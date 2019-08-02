---
author: kromey
comments: true
date: 2016-07-28 17:57:53+00:00
layout: post
link: https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-4-789.html
redirect_from: /2016/07/setting-up-an-iptables-firewall-part-4-789.html
slug: setting-up-an-iptables-firewall-part-4
title: 'Setting Up An iptables Firewall: Part 4'
wordpress_id: 789
categories:
- How-to
- Tech
tags:
- firewall
- guide
- iptables
- linux
- networking
- Security
---

In [Part 1](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-1-751.html), we set up a very basic firewall. [Part 2](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-2-759.html) added some basic additional protections to our server. [Part 3](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-3-777.html) started to get more proactive against certain types of potential attacks. In this part, we're going to introduce the `recent` module, and leverage it to make our firewall reactive to shield us from even more attacks.

Since the first thing we did in the [previous post](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-3-777.html) was to mitigate one type of potential attack, it makes sense to start with a relatively simple example that can mitigate another one, this one commonly called a "[SYN flood](https://en.wikipedia.org/wiki/SYN_flood)". We won't go into what this entails (read the linked page which includes some great pictures to illustrate it), but instead launch straight into how we can mitigate it:


    
    
    -A attacks -p tcp -m tcp --syn -m recent --name synflood --set
    -A attacks -p tcp -m tcp --syn -m recent --name synflood --rcheck --seconds 1 --hitcount 60 -j DROP
    



We're using our `tcp` module again, this time with the `--syn` argument; this means we're looking at only those initial SYN packets that [initiate a connection](https://en.wikipedia.org/wiki/Handshaking#TCP_three-way_handshake). We then load the `recent` module (`-m recent`) and specify the name of the list we want to use (`--name synflood`).

In the first rule, all we do is add this packet to the list (`--set`); for each named list, packets are listed by the address of the computer they came from. The second rule then checks for packets seen from that computer (`--rcheck`) and, if there have been 60 or more matching packets in the past second (`--seconds 1 --hitcount 60`), the packet is dropped (`-j DROP`). (Adjust this threshold for your needs: If you run a web server that serves pages with lots of little badges on it, for instance, you might need to increase it, whereas a low-traffic email server could probably get by with a lower threshold.)

In other words, we've established a maximum rate of 60 new connections per second, with anything in excess being dropped. Of course, when you say it like that, couldn't this have been implemented with the `limit` module instead? While we technically could, look more closely: Where the `limit` module specifies a rate under which we act, these rules specify a rate _over_ which we act. Since at this point in the processing (we're in the `attacks` chain here) we don't know yet if we want to accept a packet that's within our threshold, we can't use a simple `limit` rule with a `-j ACCEPT` target like we did with ICMP traffic; instead we monitor the rate and only act when it's exceeded.

This is a relatively uninteresting application of the module, however. Let's move on, and this time use it more creatively:


    
    
    -N blacklist
    -N bl_drop
    -A blacklist -p tcp -m tcp --dport 21 -j bl_drop
    -A blacklist -p tcp -m tcp --dport 23 -j bl_drop
    -A blacklist -p tcp -m tcp --dport 25 -j bl_drop
    -A blacklist -p tcp -m tcp --dport 139 -j bl_drop
    -A blacklist -p tcp -m tcp --dport 3389 -j bl_drop
    -A bl_drop -m recent --name blacklist --set -j DROP
    -A INPUT -j blacklist
    



We've created a new chain called `blacklist` and immediately populated it with some new rules before adding it to the end of the `INPUT` chain; we've also created the `bl_drop` chain. Each of the rules in the `blacklist` chain will send attempts to contact an FTP service (`--dport 21`), a Telnet service (`--dport 23`), an SMTP service (`--dport 25`), a Windows File Sharing or Samba service (`--dport 139`), or a RDP service (`--dport 3389`) to our `bl_drop` chain, which in turn adds them to a new list we've named `blacklist` before dropping them. In essence what we've done is taken any attempt to contact these commonly-exploited services and flagged the sender as a "bad guy" we don't want getting in to our server at all. By not doing any of this until the very end of the `INPUT` chain, we've accomplished two things:




    
  1. We won't accidentally blacklist ourselves if we later decide to open one of these ports and try to use it

    
  2. We preserve processing resources by not bothering with blacklisting anything we've already blocked anyway, such as martians



However, we're not actually doing anything with this list just yet, only adding addresses to it. Let's act on our new blacklist now:


    
    
    -I INPUT 5 -m recent --name blacklist --rcheck --seconds 3600 -j blacklist
    -A blacklist -j DROP
    



We've inserted this rule above the `attacks` chain, and also added a new rule to the `blacklist` chain to `DROP` everything that comes through it. Now, any computer that tries to connect to any of our blacklisted ports will find themselves unable to connect to anything at all -- even any of our opened services -- for one hour (`--seconds 3600`). Additionally, since we run them back through our `blacklist` chain again, further attempts to connect to any of the blacklisted ports will, in fact, result in the timer resetting, and they will be unable to connect for another hour.

An alternative version of this rule could use `--update` in place of `--rcheck` (and then use `-j DROP` as the target instead). This version would immediately `DROP` any packets from blacklisted addresses, but it would also cause _any_ packet from them to update the list, resetting the timer so they're blacklisted for another hour. This could potentially cause a legitimate client that simply pointed the wrong software at your server to become locked out for a long time, however, but the chances of that are probably quite slim. (Besides, if it becomes a problem with legitimate users accidentally pointing e.g. Telnet clients at your server, you could always just remove that rule from your `blacklist` chain instead.)

A third alternative could continue to use `--rcheck`, but swap out the target to `-j DROP`. This would again result in dropping packets from blacklisted addresses immediately (less processing is a great boon if you're actively under attack), however it also means that regardless of what those potential attackers have done since being initially blacklisted, they will once again be able to connect to your open services after that first hour is up.

In any case, there's one more thing we can do with our new blacklisting mechanism here: We can replace the targets on each rule in our `attacks` chain with `-j bl_drop`, immediately blacklisting any address that we notice any of those attacks coming from. I'll leave crafting the appropriate commands to replace those targets as an exercise to the reader, however.

One thing to be aware of with the blacklisting we've done here: A knowledgeable attacker could craft packets with forged headers that make them appear to come from legitimate users of your services, but targeted at your blacklisted ports; the result would be a denial of service for your legitimate users, who now find themselves blacklisted by your firewall through no fault of their own. While we might be able to mitigate this with use of the `--hitcount` argument, ultimately if you suspect this is happening the only solution is to either whitelist your legitimate users, or else drop the blacklisting altogether.

One more thing to do and then we're done here:


    
    
    -I INPUT 6 -m recent --name blacklist --remove
    



This rule, added immediately after our blacklisting rule, becomes a sort of "garbage collector": The first time an address we'd previously blacklisted connects after they've served their time, we remove their address from our list altogether. Of course, if they're still being bad we'll end up immediately re-adding them, but if the address no longer belongs to a "bad guy", or never did and was simply a legitimate user making a mistake, it reduces the resources your server requires to keep track of these lists.

A rule this simple combined with `--hitcount` on your blacklist itself, however, won't work, because it means that before anyone can reach that threshold you've already taken them off the list. No one will ever be blacklisted. You could in this case add e.g. `--seconds 86400` to this rule, requiring that you've not seen them do anything "bad" for a full day before you remove them.

Remember to save your firewall rules (`dpkg-reconfigure iptables-persistent`); with everything we've done up to this point, your rules file should now look like this (NB: I've added some additional comments to some rules here):


    
    
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :attacks - [0:0]
    :blacklist - [0:0]
    :bl_drop - [0:0]
    :icmp - [0:0]
    :martians - [0:0]
    :services - [0:0]
    -A INPUT -p icmp -j icmp
    -A INPUT -i lo -m comment --comment "Free reign for loopback" -j ACCEPT
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -m state --state INVALID -j DROP
    -A INPUT -m recent --name blacklist --rcheck --seconds 3600 -j blacklist
    -A INPUT -m recent --name blacklist --remove
    -A INPUT -m comment --comment "Handle common attacks" -j attacks
    -A INPUT -m comment --comment "Filter martians" -j martians
    -A INPUT -m comment --comment "Open service ports" -j services
    -A INPUT -j blacklist
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "NULL packets" -j bl_drop
    -A attacks -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "SYN flag checking" -j bl_drop
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -m comment --comment "XMAS packets" -j bl_drop
    -A attacks -p tcp -m tcp --syn -m recent --name synflood --set
    -A attacks -p tcp -m tcp --syn -m recent --name synflood --rcheck --seconds 1 --hitcount 60 -j bl_drop
    -A blacklist -p tcp -m tcp --dport 21 -m comment --comment "FTP" -j bl_drop
    -A blacklist -p tcp -m tcp --dport 23 -m comment --comment "Telnet" -j bl_drop
    -A blacklist -p tcp -m tcp --dport 25 -m comment --comment "SMTP" -j bl_drop
    -A blacklist -p tcp -m tcp --dport 139 -m comment --comment "SMB" -j bl_drop
    -A blacklist -p tcp -m tcp --dport 3389 -m comment --comment "RDP" -j bl_drop
    -A blacklist -j DROP
    -A bl_drop -m recent --name blacklist --set -m comment --comment "Blacklist the source" -j DROP
    -A icmp -m limit --limit 1/s --limit-burst 4 -j ACCEPT
    -A icmp -j DROP
    -A martians --source 0.0.0.0/8 -m comment --comment "'This' network" -j DROP
    -A martians --source 10.0.0.0/8 -m comment --comment "Private-use networks" -j DROP
    -A martians --source 100.64.0.0/10 -m comment --comment "Carrier-grade NAT" -j DROP
    -A martians --source 127.0.0.0/8 -m comment --comment "Loopback" -j DROP
    -A martians --source 169.254.0.0/16 -m comment --comment "Link local" -j DROP
    -A martians --source 172.16.0.0/12 -m comment --comment "Private-use networks" -j DROP
    -A martians --source 192.0.0.0/24 -m comment --comment "IETF protocol assignments" -j DROP
    -A martians --source 192.0.2.0/24 -m comment --comment "TEST-NET-1" -j DROP
    -A martians --source 192.168.0.0/16 -m comment --comment "Private-use networks" -j DROP
    -A martians --source 198.18.0.0/15 -m comment --comment "Network interconnect device benchmark testing" -j DROP
    -A martians --source 198.51.100.0/24 -m comment --comment "TEST-NET-2" -j DROP
    -A martians --source 203.0.113.0/24 -m comment --comment "TEST-NET-3" -j DROP
    -A martians --source 224.0.0.0/4 -m comment --comment "Multicast" -j DROP
    -A martians --source 240.0.0.0/4 -m comment --comment "Reserved for future use" -j DROP
    -A martians --source 255.255.255.255/32 -m comment --comment "Limited broadcast" -j DROP
    -A services -p tcp -m tcp --dport 22 -m limit --limit 1/minute -m comment --comment "Rate-limited SSH" -j ACCEPT
    -A services -p tcp -m tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    -A services -p tcp -m tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT
    COMMIT
    



Congratulations! You now have a very solid firewall configuration. There's still more room for improvement, of course, and in the next part we'll [add port knocking](https://kromey.us/2016/08/setting-up-an-iptables-firewall-part-5-810.html) to our setup!
