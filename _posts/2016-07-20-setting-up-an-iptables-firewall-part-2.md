---
author: admin
comments: true
date: 2016-07-20 14:58:49+00:00
layout: post
link: https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-2-759.html
slug: setting-up-an-iptables-firewall-part-2
title: 'Setting Up An iptables Firewall: Part 2'
wordpress_id: 759
categories:
- How-to
tags:
- firewall
- guide
- iptables
- linux
- networking
- Security
---

In [Part 1](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-1-751.html) of this series, we set up a very basic firewall that essentially just restricts what ports we can connect to without doing much else to defend our server. In this part, we're going to build from there and add additional restrictions to block a substantial portion of potentially malicious traffic that simply has no business being on the internet at all.

The first thing we're going to address are martians. No, not the little green men or [Matt Damon](http://amzn.to/2arVdCk); in this context, a [martian](https://en.wikipedia.org/wiki/Martian_packet) is an IP packet with a source address reserved for special use. Like with our opened ports from the previous part, we're going to create a separate chain and add our rules to that:


    
    
    -N martians
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
    



Nothing should be too surprising here, and I've included comments listing the [IANA](https://en.wikipedia.org/wiki/Internet_Assigned_Numbers_Authority)'s reason for reserving these networks in each rule. We have introduced the `--source` parameter, which as you can see can take a network range in [CIDR notation](https://en.wikipedia.org/wiki/Cidr) (it can also take a plain IP address, e.g. `123.45.67.89`).

Before we go any further, however, there's a _big_ caveat I have to put out here: This chain assumes that your machine is connected directly to the internet. If instead you are on a LAN or otherwise expect traffic to be coming from one of the "private-use networks", you should remove the rule corresponding to that network from this list -- a packet is not a martian if it comes from an address that makes sense to be sending to your machine!

Now, of course, we need to add a rule to the `INPUT` chain so that our firewall will actually use it. However, we can't simply use the `-A` argument we've become so familiar with: That would _A_ppend the rule to the end of the `INPUT` chain, which means that we would not prevent these martians from connecting to our opened services! Clearly that's not what we want, so how do we put the rule into the order we want it in?

The answer is that we use the `-I` argument to _I_nsert the rule into our chain. First we need to know what the current order is, and for that we will use the `-L` argument to _L_ist the rules, as well as the `--line-num` argument to show their line numbers:


    
    
    $ sudo iptables -L INPUT --line-num
    Chain INPUT (policy DROP)
    num  target     prot opt source               destination         
    1    ACCEPT     icmp --  anywhere             anywhere             /* Allow ICMP */
    2    ACCEPT     all  --  anywhere             anywhere             /* Free reign for loopback */
    3    ACCEPT     all  --  anywhere             anywhere             state RELATED,ESTABLISHED
    4    DROP       all  --  anywhere             anywhere             state INVALID
    5   services   all  --  anywhere             anywhere             /* Open service ports */
    



Now we can see that our `services` chain is invoked from rule #5; we want our new `martians` chain to take that place, however, so we tell `-I` that we want to insert our new rule so that it's now #5, pushing the existing one down further in the list:


    
    
    -I INPUT 5 -m comment --comment "Filter martians" -j martians
    



If you now repeat the above listing command, you'll see our new rule is now #5 in the list, while the rule that invokes our `services` chain has been moved to become #6.

Now that that's taken care of, let's also block some common attacks that script kiddies and hackers will often use to try and exploit servers on the internet. We'll once again put these rules into a separate chain:


    
    
    -N attacks
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "NULL packets" -j DROP
    -A attacks -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "SYN flag checking" -j DROP
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -m comment --comment "XMAS packets" -j DROP
    



Since all of these rules are based on flags in the TCP packet's header, we restrict matches to the TCP protocol (`-p tcp`) and then load the `tcp` module (`-m tcp`). We've also added comments to each of these to provide a clue as to what they do, but we're just going to gloss over them for now -- each of these rules describes a packet with header flags that should never be seen in a legitimate connection attempt, and which are used solely in various attacks and reconnaissance methods.

Remember back in Part 1 when I mentioned that the `RELATED,ESTABLISHED` rule would be crucial to the rest of our design? Here we see that in action: Our `attacks` chain here is built under the assumption that we are only worried about packets that aren't part of any existing connection. Without that rule in place, we would have to reconsider how we detect potential attacks in this chain.

One more thing I will point out is the second rule (third line, "SYN flag checking"), and specifically the appearance of the `!` character in the argument list. This is the "not" operator, and it inverts the meaning of the following condition from "packets which match" to instead mean "packets which do not match". In practice there's not often a call for this operator, but when it's needed it's incredibly valuable -- without it implementing such a case would either require incredibly careful ordering of rules in our chain (resulting in something very fragile and more difficult to maintain), or create an entirely separate chain to replace this one simple rule.

Once again, however, we can't simply add this one to the end of our `INPUT` chain, or else it won't protect our services! There's no hard and fast rule about whether this one should come before or after the martians rule we just inserted above, however in general you want to drop "bad" packets as early as possible; from watching the counters on my own server, I see more being dropped from this chain than I see martians, so I'm going to insert it above the `martians` chain:


    
    
    -I INPUT 5 -m comment --comment "Handle common attacks" -j attacks
    



(You can -- and, until you're really comfortable with `iptables`, absolutely should -- always review the listing with `sudo iptables -L INPUT --line-num` before inserting a new rule like this, however here I know that we haven't done anything else to the `INPUT` chain since inserting the `martians` chain as rule #5, and therefore I know that I can insert this one at rule #5, which will push the `martians` chain to rule #6, and the `services` chain will become rule #7; check the output listing again to see!)

That's it for Part 2! We've enhanced the security of our system now by proactively blocking traffic that has no legitimate business coming to us. We'll continue to build on this as we add in additional protections. To save our new changes, if you've already installed the `iptables-persistent` package (from [Part 1](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-1-751.html)) you can run this command (at least on Debian-based systems):


    
    
    $ sudo dpkg-reconfigure iptables-persistent
    



This will prompt the package to once again ask you if you want to save the current rules; tell it "yes", and once again the file `/etc/iptables/rules.v4` will be updated with your current configuration. Your file should now look (in part) like this:


    
    
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :attacks - [0:0]
    :martians - [0:0]
    :services - [0:0]
    -A INPUT -p icmp -m comment --comment "Allow ICMP" -j ACCEPT
    -A INPUT -i lo -m comment --comment "Free reign for loopback" -j ACCEPT
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -m state --state INVALID -j DROP
    -A INPUT -m comment --comment "Handle common attacks" -j attacks
    -A INPUT -m comment --comment "Filter martians" -j martians
    -A INPUT -m comment --comment "Open service ports" -j services
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "NULL packets" -j DROP
    -A attacks -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "SYN flag checking" -j DROP
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -m comment --comment "XMAS packets" -j DROP
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
    -A services -p tcp -m tcp --dport 22 -m comment --comment "SSH" -j ACCEPT
    -A services -p tcp -m tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    -A services -p tcp -m tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT
    COMMIT
    



Next stop, we learn about the `limit` module in [Part 3](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-3-777.html)!
