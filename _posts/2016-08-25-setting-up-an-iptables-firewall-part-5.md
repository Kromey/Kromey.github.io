---
author: admin
comments: true
date: 2016-08-25 23:52:13+00:00
layout: post
link: https://kromey.us/2016/08/setting-up-an-iptables-firewall-part-5-810.html
redirect_from: /2016/08/setting-up-an-iptables-firewall-part-5-810.html
slug: setting-up-an-iptables-firewall-part-5
title: 'Setting Up An iptables Firewall: Part 5'
wordpress_id: 810
categories:
- How-to
tags:
- firewall
- guide
- iptables
- linux
- networking
- port knocking
- Security
---

If you've followed along with the previous posts so far, you've already got yourself a solid firewall configuration: We only allow traffic to the ports we're actually running services on; we proactively guard against common attacks; and we reactively blacklist the bad guys. But there's still more we can do, and in this part we're going to use a technique called port knocking to make it even more difficult for anyone to access our SSH service.

Before you go any further here, you probably want to have read the previous posts in this series. Of course, if you're in a hurry and already know how to configure `iptables`, and all you're looking for is how to implement port knocking, read on -- though you may want to at the very least refer to the final configuration at the end of [Part 4](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-4-789.html), as we'll be integrating this approach into that.

First, let's talk about what [port knocking](https://en.wikipedia.org/wiki/Port_knocking) is. Put simply, it's analogous to locking away your server behind a combination lock: Only the correct sequence of packets sent to specific ports will "unlock" the service(s) we've guarded behind it. Some argue that it is little more than "security through obscurity", on the basis that anyone who can observe your network traffic can easily learn the sequence; while there are solutions to mitigate this (e.g. the misleadingly-named "Single-Packet Authorization"), this argument misses the point: Security isn't _based_ on port knocking, but rather existing security (e.g. password-based authentication) is being _augmented_, as one more layer of the "onion of security".

Now, Single-Packet Authentication shouldn't be dismissed, but as it requires an additional daemon to read and decrypt the encrypted packets, we won't be discussing it further. Instead, we'll implement port knocking purely within `iptables`. And, unlike other examples of this technique I've seen out there, we're going to do it all in a single chain.

To build this, we're going to start with the basic building blocks. Forget about everything else, and for now think about just a single "knock" (i.e. a packet sent to our server as part of the port knocking sequence): We want to know that a given computer has "knocked" on the correct port when we examine subsequent packets from that same source. Fortunately, since we've already made use of the `match` module, we know precisely how to do this:


    
    
    -A portknock -p XXX -m XXX --dport XXXX -m recent --set --name knock{N}
    



We'll fill in the particulars -- protocol, port -- later, we just need to start with our basic building blocks. And this is a good first step: With this rule, when a packet matches our criteria we make a note of that, which we can reference later.

Speaking of "later", though, don't we need to make sure that the previous knock in our sequence was hit before we note this one? Indeed we do! Fortunately, we also know how to do this from the `recent` module, so our pattern above transforms into this:


    
    
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock{N-1} -m recent --set --name knock{N}
    



Again, the particulars we'll fill in later. Remembering that rules are read left-to-right, and that we only continue if a given check passes, we've inserted an `rcheck` condition that will verify that we saw the sender send the previous knock within the last XX seconds, and only if that is the case do we make a note of the current knock.

There's still one more thing to do, though. If we were to run toward the finish line now, rolling out this pattern to implement our port knocking sequence, there'd be a serious problem: A flood of packets to every port could easily trick this too-naïve solution into unlocking the guarded port! To prevent this, we need to ensure that an out-of-sequence knock forces the knocking computer to start over from the beginning:


    
    
    -A portknock -m recent --remove --name knock{N}
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock{N-1} -m recent --set --name knock{N}
    



Now, before we do any checking of whether or not a packet is a match for our current knock, we remove the sender from the list of matches for this knock. This might seem superfluous at first, but remember our analogy of the combination lock: If your combination is 12-37-43, you don't want somebody who tries the combination 12-34-89-37-43 to get in, do you? This is why we always remove a match before we check for it: Once all the pieces have been put together, it ensures that any non-matching packet will "break" the port knocking sequence and not allow the sender access, by ensuring that at any given point a computer is only listed at most as being at one point in the sequence, and removing them entirely if they misstep.

This has an interesting side effect, however: When we put all the pieces together and implement the sequence, we have to do so from the _bottom_ up in the chain. Otherwise we'll remove someone from having matched, say, knock1, see that they don't match knock1, and then not even check them for knock2 because they haven't matched knock1!

So with that in mind, let's put together our rules for a 3-knock sequence:


    
    
    -A portknock -m recent --remove --name knock3
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock2 -m recent --set --name knock3
    -A portknock -m recent --remove --name knock2
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock1 -m recent --set --name knock2
    -A portknock -m recent --remove --name knock1
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock0 -m recent --set --name knock1
    



Whoopsie! Look at that last rule -- per our pattern, we need to have matched the previous knock before we can match the current knock, but when we're checking the first one there is no previous one! We could add a rule at the end to set a phantom "knock0", but it's better to just remove that condition from the rule entirely, though of course only for the first knock.

We also aren't yet doing anything once the sequence has been completed. Since we set out at the beginning of this post saying we were going to protect our SSH service, let's do precisely that:


    
    
    -A portknock -p tcp -m tcp --dport 22 -m recent --rcheck --seconds XX --name knock3 -j ACCEPT
    -A portknock -m recent --remove --name knock3
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock2 -m recent --set --name knock3
    -A portknock -m recent --remove --name knock2
    -A portknock -p XXX -m XXX --dport XXXX -m recent --rcheck --seconds XX --name knock1 -m recent --set --name knock2
    -A portknock -m recent --remove --name knock1
    -A portknock -p XXX -m XXX --dport XXXX -m recent --set --name knock1
    



You can protect multiple services with the same sequence by replicating the first rule for different ports, e.g. an email relay server that only talks to clients which have sent the proper knock sequence first. Remember, port knocking should not be your only line of defense, but it will cut down the attempts to brute force your passwords or exploit protocol/service vulnerabilities nearly to zero.

You might also want to consider removing the second rule above, the `--remove --name knock3` rule. Removing this one would mean that once a computer has sent that third knock, no matter what else it sends it will stay in that state of having completed the knocking sequence. This doesn't permanently unlock the protected services, of course -- we still have the `--rcheck --seconds XX --name knock3` condition on our first rule to limit it to only those who have completed in the last XX seconds -- but it does mean that once someone has passed in the correct knock sequence, they can utilize the server fully without having to re-knock every time they want to initiate a new connection.

Now that we have our template, it's time to fill in the final values. You should always choose non-consecutive ports for your sequence so that a simple port scan won't inadvertently unlock it, and you should avoid picking common service ports. Pick your own sequence, but for this example I'll use a sequence of TCP packets to ports 1234, 2345, and 3456. I'll also decide that each knock must come within 10 seconds of the previous knock, and that once we complete the sequence we won't need to knock again for 1 hour. Putting all that together (and remembering the rules are in reverse order of the sequence), we end up with this:


    
    
    -A portknock -p tcp -m tcp --dport 22 -m recent --rcheck --seconds 3600 --name knock3 -j ACCEPT
    -A portknock -p tcp -m tcp --dport 3456 -m recent --rcheck --seconds 10 --name knock2 -m recent --set --name knock3
    -A portknock -m recent --remove --name knock2
    -A portknock -p tcp -m tcp --dport 2345 -m recent --rcheck --seconds 10 --name knock1 -m recent --set --name knock2
    -A portknock -m recent --remove --name knock1
    -A portknock -p tcp -m tcp --dport 1234 -m recent --set --name knock1
    



There you have it! A single chain implementing a 3-step port knocking sequence to protect our SSH service!

We could use port knocking to not just allow us access to secure services like SSH, but also to give us an "escape hatch" out of the blacklisting from the [previous post](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-4-789.html), just in case we manage to accidentally blacklist ourselves. Ideally, you'd come up with a second secret sequence, but to save time and space here I'll simply add it to our current one instead:


    
    
    -A portknock -m recent --rcheck --seconds 3600 --name knock3 -m recent --remove --name blacklist
    -A portknock -p tcp -m tcp --dport 22 -m recent --rcheck --seconds 3600 --name knock3 -j ACCEPT
    -A portknock -p tcp -m tcp --dport 3456 -m recent --rcheck --seconds 10 --name knock2 -m recent --set --name knock3
    -A portknock -m recent --remove --name knock2
    -A portknock -p tcp -m tcp --dport 2345 -m recent --rcheck --seconds 10 --name knock1 -m recent --set --name knock2
    -A portknock -m recent --remove --name knock1
    -A portknock -p tcp -m tcp --dport 1234 --set --name knock1
    



Now, any connection attempted within 1 hour of completing the port knocking sequence will remove the sender from the blacklist. Of course, for this to work, we need to insert the jump into this chain above the blacklist check in the INPUT chain, but even without the de-listing this one does that's not a bad idea, as it gives us emergency access even if we do blacklist ourselves, and having access to SSH in this way without the blacklist protection is still quite secure, as a potential attacker still needs to send the proper knock sequence just to know that there's an SSH server to attack in the first place! Of course, we also need to remove SSH from our `services` chain as well.

Putting everything together, if you've followed this series so far, after you save your firewall configuration (`sudo dpkg-reconfigure iptables-persistent`), yours should look something like this:


    
    
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
    
