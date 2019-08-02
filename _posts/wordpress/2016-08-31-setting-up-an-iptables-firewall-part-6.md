---
author: kromey
comments: true
date: 2016-08-31 01:23:14+00:00
layout: post
link: https://kromey.us/2016/08/setting-up-an-iptables-firewall-part-6-818.html
redirect_from: /2016/08/setting-up-an-iptables-firewall-part-6-818.html
slug: setting-up-an-iptables-firewall-part-6
title: 'Setting Up An iptables Firewall: Part 6'
wordpress_id: 818
categories:
- How-to
- Tech
tags:
- firewall
- guide
- iptables
- ipv6
- linux
- networking
- Security
---

It's been a long journey, and we've learned a lot along the way. We've created a robust firewall configuration that includes proactive and reactive defenses, as well as incorporated advanced port knocking protections to guard our restricted services more strongly. Everything up until now, however, has been strictly IPv4; if your server is also on the IPv6 network, it is still wide-open to all! This post will be shorter than the others in this series, because all we're doing is adapting our current IPv4 rules to IPv6.

The `iptables` command is specifically the IPv4 command; it has a nigh-identical IPv6 counterpart called `ip6tables`. There are also IPv6 counterparts of `iptables-save` and `iptables-restore`, called (shockingly) `ip6tables-save` and `ip6tables-restore`. Almost everything we have done through this series can simply swap in the `ip6tables` command instead of `iptables`, and set up your firewall that way.

In fact, they are so identical that the fastest way to get your IPv6 firewall up and running is to copy your `/etc/iptables/rules.v4` file to `/etc/iptables/rules.v6`! That's not _quite_ all there is to it, however. If you've paid close attention to the file excerpts I have posted at the end of each previous post, you'll notice I've left a few things out for the sake of readability; these omitted arguments don't change the outcome because they are, in fact, the defaults, but there's one such argument that we have to change here because it only works for IPv4: In many of your rules, you will see a `--mask 255.255.255.255` argument. This is simply applying a bitmask to the IP address, and in this case is saying "match the entire address". Fortunately, this happens to be a default, so the easiest way to fix these in your rules.v6 file to make it work for IPv6 is to simply delete every occurrence of `--mask 255.255.255.255`.

There's still one more fix we have to make, but it's a bit of a doozy. Our `martians` chain is, unfortunately, specifically addressing IPv4 martians. In addition to doing nothing to benefit our IPv6 firewall, these rules will actually fail to run at all, and cause the entire file to fail to be executed. We have to replace these rules with ones that will block IPv6 martians. Those look like this:


    
    
    -A martians --source ::/96 -m comment --comment "IPv4-compatible IPv6 address – deprecated by RFC4291" -j DROP
    -A martians --source ::/128 -m comment --comment "Unspecified address" -j DROP
    -A martians --source ::1/128 -m comment --comment "Local host loopback address" -j DROP
    -A martians --source ::ffff:0.0.0.0/96 -m comment --comment "IPv4-mapped addresses" -j DROP
    -A martians --source ::224.0.0.0/100 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source ::127.0.0.0/104 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source ::0.0.0.0/104 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source ::255.0.0.0/104 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source 0000::/8 -m comment --comment "Pool used for unspecified, loopback and embedded IPv4 addresses" -j DROP
    -A martians --source 0200::/7 -m comment --comment "OSI NSAP-mapped prefix set (RFC4548) – deprecated by RFC4048" -j DROP
    -A martians --source 3ffe::/16 -m comment --comment "Former 6bone, now decommissioned" -j DROP
    -A martians --source 2001:db8::/32 -m comment --comment "Reserved by IANA for special purposes and documentation" -j DROP
    -A martians --source 2002:e000::/20 -m comment --comment "Invalid 6to4 packets (IPv4 multicast)" -j DROP
    -A martians --source 2002:7f00::/24 -m comment --comment "Invalid 6to4 packets (IPv4 loopback)" -j DROP
    -A martians --source 2002:0000::/24 -m comment --comment "Invalid 6to4 packets (IPv4 default)" -j DROP
    -A martians --source 2002:ff00::/24 -m comment --comment "Invalid 6to4 packets" -j DROP
    -A martians --source 2002:0a00::/24 -m comment --comment "Invalid 6to4 packets (IPv4 private 10.0.0.0/8 network)" -j DROP
    -A martians --source 2002:ac10::/28 -m comment --comment "Invalid 6to4 packets (IPv4 private 172.16.0.0/12 network)" -j DROP
    -A martians --source 2002:c0a8::/32 -m comment --comment "Invalid 6to4 packets (IPv4 private 192.168.0.0/16 network)" -j DROP
    -A martians --source fc00::/7 -m comment --comment "Unicast Unique Local Addresses (ULA) – RFC 4193" -j DROP
    -A martians --source fe80::/10 -m comment --comment "Link-local Unicast" -j DROP
    -A martians --source fec0::/10 -m comment --comment "Site-local Unicast – deprecated by RFC 3879 (replaced by ULA)" -j DROP
    -A martians --source ff00::/8 -m comment --comment "Multicast" -j DROP
    



Swap those in for the entire list of `-A martians` rules from your IPv4 rules, and now we're done adapting our firewall to IPv6! With your copied-and-updated `rules.v6` file, you can simply run the command `sudo ip6tables-restore < /etc/iptables/rules.v6` to build your IPv6 firewall into a matching state with your IPv4 one!

And with that, we already reach the end of this post. Your rules.v4 file should be no different from what you had at the end of Part 5, but now we have rules.v6 with this content:


    
    
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :attacks - [0:0]
    :blacklist - [0:0]
    :bl_drop - [0:0]
    :icmp - [0:0]
    :martians - [0:0]
    :portknock - [0:0]
    :services - [0:0]
    -A INPUT -p icmp -j icmp
    -A INPUT -i lo -m comment --comment "Free reign for loopback" -j ACCEPT
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -m state --state INVALID -j DROP
    -A INPUT -m comment --comment "Guard SSH with port knocking" -j portknock
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
    -A martians --source ::/96 -m comment --comment "IPv4-compatible IPv6 address – deprecated by RFC4291" -j DROP
    -A martians --source ::/128 -m comment --comment "Unspecified address" -j DROP
    -A martians --source ::1/128 -m comment --comment "Local host loopback address" -j DROP
    -A martians --source ::ffff:0.0.0.0/96 -m comment --comment "IPv4-mapped addresses" -j DROP
    -A martians --source ::224.0.0.0/100 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source ::127.0.0.0/104 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source ::0.0.0.0/104 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source ::255.0.0.0/104 -m comment --comment "Compatible address (IPv4 format)" -j DROP
    -A martians --source 0000::/8 -m comment --comment "Pool used for unspecified, loopback and embedded IPv4 addresses" -j DROP
    -A martians --source 0200::/7 -m comment --comment "OSI NSAP-mapped prefix set (RFC4548) – deprecated by RFC4048" -j DROP
    -A martians --source 3ffe::/16 -m comment --comment "Former 6bone, now decommissioned" -j DROP
    -A martians --source 2001:db8::/32 -m comment --comment "Reserved by IANA for special purposes and documentation" -j DROP
    -A martians --source 2002:e000::/20 -m comment --comment "Invalid 6to4 packets (IPv4 multicast)" -j DROP
    -A martians --source 2002:7f00::/24 -m comment --comment "Invalid 6to4 packets (IPv4 loopback)" -j DROP
    -A martians --source 2002:0000::/24 -m comment --comment "Invalid 6to4 packets (IPv4 default)" -j DROP
    -A martians --source 2002:ff00::/24 -m comment --comment "Invalid 6to4 packets" -j DROP
    -A martians --source 2002:0a00::/24 -m comment --comment "Invalid 6to4 packets (IPv4 private 10.0.0.0/8 network)" -j DROP
    -A martians --source 2002:ac10::/28 -m comment --comment "Invalid 6to4 packets (IPv4 private 172.16.0.0/12 network)" -j DROP
    -A martians --source 2002:c0a8::/32 -m comment --comment "Invalid 6to4 packets (IPv4 private 192.168.0.0/16 network)" -j DROP
    -A martians --source fc00::/7 -m comment --comment "Unicast Unique Local Addresses (ULA) – RFC 4193" -j DROP
    -A martians --source fe80::/10 -m comment --comment "Link-local Unicast" -j DROP
    -A martians --source fec0::/10 -m comment --comment "Site-local Unicast – deprecated by RFC 3879 (replaced by ULA)" -j DROP
    -A martians --source ff00::/8 -m comment --comment "Multicast" -j DROP
    -A portknock -m recent --rcheck --seconds 3600 --name knock3 -m recent --remove --name blacklist
    -A portknock -p tcp -m tcp --dport 22 -m recent --rcheck --seconds 3600 --name knock3 -j ACCEPT
    -A portknock -p tcp -m tcp --dport 3456 -m recent --rcheck --seconds 10 --name knock2 -m recent --set --name knock3
    -A portknock -m recent --remove --name knock2
    -A portknock -p tcp -m tcp --dport 2345 -m recent --rcheck --seconds 10 --name knock1 -m recent --set --name knock2
    -A portknock -m recent --remove --name knock1
    -A portknock -p tcp -m tcp --dport 1234 --set --name knock1
    -A services -p tcp -m tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    -A services -p tcp -m tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT
    COMMIT
    



That concludes this series, although I will likely continue to introduce additional concepts and tips for managing your ``iptables`/`ip6tables` firewalls in future posts.
