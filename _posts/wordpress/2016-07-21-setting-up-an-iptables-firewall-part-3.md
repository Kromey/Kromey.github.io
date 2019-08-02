---
author: kromey
comments: true
date: 2016-07-21 23:37:22+00:00
layout: post
link: https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-3-777.html
redirect_from: /2016/07/setting-up-an-iptables-firewall-part-3-777.html
slug: setting-up-an-iptables-firewall-part-3
title: 'Setting Up An iptables Firewall: Part 3'
wordpress_id: 777
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

In [Part 1](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-1-751.html), we created a very basic firewall setup that only allowed traffic to the services our server actually provides. In [Part 2](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-2-759.html), we took it up a notch by proactively blocking traffic that had no business reaching our server in the first place. Now, we're going to augment our configuration to be even more proactive, introducing the `limit` module to slow down potential attackers.

The `limit` module is pretty much exactly what it sounds like: It gives us a way to easily limit the amount of traffic a rule will accept. This can be handy if you want to log traffic for later analysis, but don't want to fill your hard disk, or if you just want to rate-limit new connections to your services.

We'll illustrate this with a simple example. If you'll recall from all the way back in [Part 1](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-1-751.html), one of the first things we did -- in fact, literally the first rule we added -- was to permit all ICMP traffic. This is fine and dandy, but it does open the possibility that our server could be used as the middle-man in a [smurf attack](https://en.wikipedia.org/wiki/Smurf_attack), where an attacker forges his IP address to trick our server into sending ICMP replies to his victim. While detecting such forgeries is beyond the capabilities of `iptables`, we can take steps to reduce our server's potential role in such an attack by limiting how many ICMP packets we'll respond to in a given time period. We'll spin this off into a new chain:


    
    
    -N icmp
    -A icmp -m limit --limit 1/s --limit-burst 4 -j ACCEPT
    -A icmp -j DROP
    



In this chain, the first rule leverages the `limit` module so that we will only accept a maximum of 1 ICMP packet per second (the module tracks such rates on a per-IP basis, that is if 5 different computers were to ping us simultaneously we would respond at a rate of up to 5 per second total, but never exceeding 1 per second to any one computer). We can specify limits in terms of seconds, minutes, hours, or days, using either the full word or, as we did here, the abbreviation. The second rule is just there to keep things explicit that we're going to ignore anything above the rate specified in the first one; in reality simply letting them "fall through" would be sufficient to ensure that they're dropped, but being explicit like this helps to keep the configuration clear and easy to understand, which will be a huge boon to us as we add more and more complexity.

If only 1 ICMP packet per second seems too low, don't worry: `--limit-burst 4` is here to take care of that. This argument simply tells the firewall how many packets we should accept _before_ the limit actually kicks in. In this case, we'll accept 4 packets from a given computer, and then limit ourselves to only accepting 1 packet from that computer per second. The burst is "recharged" at the same rate as specified by `--limit`, but only if there are no matching packets during that period; this means that for every full second that passes without an ICMP packet arriving from a computer, its burst allotment regains 1, until it reaches the limit we specified or until another packet arrives (which counts against the burst again, until that is exhausted).

(Note: The default for `--limit-burst` is 5, so if you don't specify a different burst you will actually accept 5 packets before your `--limit` kicks in!)

Astute readers will also notice something missing now: There's no `-p icmp` to restrict these rules just to the ICMP packets we're concerned with! We address that with how we connect to this chain from our `INPUT` chain:


    
    
    -R INPUT 1 -p icmp -j icmp
    



Recalling from the [previous post](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-2-759.html) that `-R` is how we replace rules, and examining the output of `sudo iptables -L INPUT --line-num` to see that our original ICMP rule was indeed rule #1, this new rule replaces the old ICMP rule and says that only ICMP packets (`-p icmp`) will be sent to the `icmp` chain (`-j icmp`). Implementing the protocol condition on the "jump rule", rather than putting it on every rule in the chain, simplifies the processing that the firewall has to do as it checks packets against each rule. When you have a common condition like this, it's often beneficial to create a separate chain for those rules, omit that condition on them, and instead use a dedicated "jump rule" like this so the condition is checked only once.

While we're on the subject of rate-limiting, let's beef up the security on our SSH port. If you've ever looked at the auth log of a server running SSH and connected directly to the internet, you've no doubt seen the never-ending stream of authentication failures from random IP addresses all over the world as various ill-meaning individuals try to get in. We can't really stop them completely, but we can slow them down dramatically:


    
    
    -R services 1 -p tcp -m tcp --dport 22 -m limit --limit 1/minute -m comment --comment "Rate-limited SSH" -j ACCEPT
    



(We again are replacing a rule; always check the output of `sudo iptables -L {chain} --line-num` before replacing or inserting a rule to make sure you're putting your new one in the right place!)

This looks very similar to the SSH rule that we already had in place, although now we've added a rate limit to it -- in this case, I've specified that only 1 connection per minute is allowed, but remember that since I didn't specify a different burst that the first 5 connection attempts will be allowed before this rate kicks in! In effect, this means that in the first 60 seconds after someone first tries to connect to your SSH server, they can only open a total of 5 connections; after that, they are limited to only 1 per minute, although as time passes their burst will recharge until they once again are allowed their max allotment of 5. (Feel free to tweak the rate and burst to your own needs or preferences, this is just my example; just don't forget that sometimes people will mistype their password, so don't set the limits so low that they are unduly punished for that.)

Also remember that, since we have a separate rule early in our `INPUT` chain for `ESTABLISHED` connections, this rate limit only applies to _new_ connections: Assuming the connections are made within the limitations set forth here, there's nothing stopping someone from having a dozen SSH connections open to your server. (If this weren't the case and we weren't already handling established connections elsewhere, this rule would basically make SSH useless, since 1 packet per minute is far too slow for a connection to function!)

By now, for those following along here's what you should have in your `rules.v4` file after saving them again with `dpkg-reconfigure iptables-persistent`:


    
    
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :attacks - [0:0]
    :icmp - [0:0]
    :martians - [0:0]
    :services - [0:0]
    -A INPUT -p icmp -j icmp
    -A INPUT -i lo -m comment --comment "Free reign for loopback" -j ACCEPT
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -m state --state INVALID -j DROP
    -A INPUT -m comment --comment "Handle common attacks" -j attacks
    -A INPUT -m comment --comment "Filter martians" -j martians
    -A INPUT -m comment --comment "Open service ports" -j services
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m comment --comment "NULL packets" -j DROP
    -A attacks -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m comment --comment "SYN flag checking" -j DROP
    -A attacks -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -m comment --comment "XMAS packets" -j DROP
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
    



We'll add better protections like dynamic blacklisting in [Part 4](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-4-789.html)!
