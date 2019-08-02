---
author: admin
comments: true
date: 2016-07-19 17:59:40+00:00
layout: post
link: https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-1-751.html
redirect_from: /2016/07/setting-up-an-iptables-firewall-part-1-751.html
slug: setting-up-an-iptables-firewall-part-1
title: 'Setting Up An iptables Firewall: Part 1'
wordpress_id: 751
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

This is the first in a series of blog posts that will walk you through how to set up a secure firewall to help protect your internet-facing Linux machines. All you have to know to be able to follow along is how to log into your machine and run command line programs, including how to use `sudo`; everything else we do will be explained along the way.

The `iptables` application is a tool that allows you, the administrator, to manipulate the tables in the operating system's firewall. While there are a number of other tools available, few if any provide the level of detail and control that we'll need in later parts of this series.

This series won't go into the internals of how the Linux system's firewall works, nor will we spend much time discussing the hows whats and whys of the structuring of the rules. (For those who do want to delve into this, it's important to know that we are talking about the Netfilter tables built into the Linux kernel.) It is, however, important to know that, at the highest level, all rules are grouped into "tables" that are responsible for different types of network traffic; for our purposes here, we're going to focus on the `filter` table, which, conveniently, is the default one, so we can completely ignore this level of organization. Within each table, rules are grouped into "chains", which -- as the name implies -- chain rules together into deterministic sequences that are evaluated one after the other. Rules are resolved in order until one acts on the packet, typically either accepting or rejecting it.

In the `filter` table we're focused on in this series, there are three default chains: `INPUT`, `FORWARD`, and `OUTPUT`. The first and last chains are self-explanatory, being applied to packets coming into and leaving from our system, respectively; the `FORWARD` chain is applied to packets being forwarded through our system, such as if it were being used as a network gateway or router. We will be starting with the `INPUT` chain, and then adding some of our own as we go along; we could use the OUTPUT chain as well to restrict the outbound connections our system could make, but for now at least we'll leave it as a permissive setup that allows all outgoing connections.

These default chains have "policies", essentially a "default" rule that will apply to any traffic that isn't acted on by other rules. By default, they all are set to the "ACCEPT" policy -- if they weren't, you would never be able to connect to your system before you configured the firewall! On the other hand, this means anyone can connect to anything, which is also not desirable, but don't worry: We will change the policy, we just have to set up a few rules first so we can still manage our servers remotely!

We'll start by adding a few "boilerplate" rules to our INPUT chain:


    
    
    $ sudo iptables -A INPUT -p icmp -m comment --comment "Allow ICMP" -j ACCEPT
    $ sudo iptables -A INPUT -i lo -m comment --comment "Free reign for loopback" -j ACCEPT
    $ sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    $ sudo iptables -A INPUT -m state --state INVALID -j DROP
    



Don't worry, we're going to dissect these rules so you know what we're doing to your firewall.

Each of these rules is being added to the `INPUT` chain, as indicated by `-A INPUT`: the `-A` flag says "add this rule to this chain". The first 3 rules establish types of traffic we will allow into our system (`-j ACCEPT`), while the last specifies a type we are going to explicitly disallow (`-j DROP`). The `-j` flag says "jump to this target"; while the "target" can be (and later on often will be) another chain, `ACCEPT` and `DROP` (and also `REJECT`, though we won't be using that one) are built-in targets that accept, ignore, or reject the packet, and terminate further processing on it.

So, now, what are these rules actually doing? Rules are essentially one or more conditions and an action to take if all the conditions match. Each of these rules has a different set of conditions:




    
  1. In the first rule, we match ICMP packets (`-p ICMP`; `-p` means we are specifying the protocol) such as ping requests

    
  2. The second rule matches anything on the loopback interface (`-i lo`; `-i` means we are specifying the protocol)

    
  3. The third rule matches packets that are part of "related" or "established" connections (`--state RELATED,ESTABLISHED`)

    
  4. The final rule matches packets that are for one reason or another invalid (`--state INVALID`)



The last two rules both also have the additional requirement that we first load the relevant module (`-m state`) that provides the `--state` flag we then use; you'll see this a lot, since `iptables` is a very modular design and except for the most rudimentary use-cases requires one or more modules to be loaded to process each rule. In fact, you also see this in the first two rules as well (`-m comment --comment "This is a comment"`); the `comment` module simply allows us to add textual comments to our rules to help us to figure out later what those rules are doing.

The third rule is crucial to later rules we will write. Essentially, by including it here early in the `INPUT` chain, it means that later rules only have to be concerned about the conditions that need to be met for establishing a new connection; once a connection has been made, this rule will ensure that future packets that are part of it will be accepted and allowed to continue. One downside to this approach is that if a malicious attacker has already established a connection we can't lock them out by closing the hole in the firewall that they used to connect in the first place; on the other hand, however, it means that if we make a mistake while managing the server remotely, we won't kill our SSH session and lock ourselves out! In practice, we're actually far more likely to accidentally lock ourselves out than to fail to lock out an attacker, so this is fine -- just be aware of this for the off chance that you later find yourself trying to lock out an attacker!

At this point, we now have a... well, it's still a very wide-open firewall. We've not really closed anything off, not meaningfully anyway.

While the set of ports you'll want to open will vary based on what your server is actually doing, for our example we'll assume you're running a web server that listens for both HTTP and HTTPS (ports 80 and 443, respectively) and that is managed remotely via SSH (port 22), so those are the port we'll open. To help keep things clean, we'll create a separate chain to simplify management: (NOTE: From here on out, I'm going to omit the `sudo iptables` command and just show you the parameters you would pass to it, for the sake of brevity)


    
    
    -N services
    -A services -p tcp -m tcp --dport 22 -m comment --comment "SSH" -j ACCEPT
    -A services -p tcp -m tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    -A services -p tcp -m tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT
    



First, we have to create the new chain (`-N services`). We then add all these rules to that chain (`-A services`). All three of these rules follow the same pattern: We match only TCP packets (`-p tcp`), we load the `tcp` module (`-m tcp`), and we match packets destined for the relevant port (e.g. `--dport 22`). We've also added a comment, and each rule jumps to the `ACCEPT` target to indicate that we want to allow these packets into our system.

That's all well and good, except that it's not going to do anything at all for us just yet. This is because packets arriving at our box go into the `INPUT` chain, and trigger the policy if they reach the end of it -- there's no automatic "go to the next chain" in `iptables`! To make this chain actually do anything, we have to tell the firewall that we want to go to it; we do this from the `INPUT` chain:


    
    
    -A INPUT -m comment --comment "Open service ports" -j services
    



Well, that's not true, actually. While we have indeed "opened" these ports for our services, we have not done anything to actually restrict anything else -- in effect, _all_ ports are open still!

While you might be tempted to add a rule to the end of your `INPUT` chain to drop everything else, there's actually a better way: Change the "policy" of the chain, which is basically the same thing but with the added advantage that we never have to worry about accidentally putting a rule after it:


    
    
    -P INPUT DROP
    



_Now_ we're done configuring our firewall (for now, anyway). However, if you were to reboot your system right now, everything we've done here would be lost! This is because rules added to the kernel's firewall are not persistent, so we need to save them. This can be easily managed for us thanks to a package called `iptables-persistent`, which is available for Debian-based systems with a simple `sudo apt-get install iptables-persistent` (other systems probably have this or a very similar package as well). When you install it, it will ask you if you want to save the current rules; say "yes", and from here on out your rules will be loaded up again every time you restart your computer.

You can find the rules in the file `/etc/iptables/rules.v4`. Assuming you've followed along with everything so far, yours will look (in part) like this:


    
    
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :services - [0:0]
    -A INPUT -p icmp -m comment --comment "Allow ICMP" -j ACCEPT
    -A INPUT -i lo -m comment --comment "Free reign for loopback" -j ACCEPT
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -m state --state INVALID -j DROP
    -A INPUT -m comment --comment "Open service ports" -j services
    -A services -p tcp -m tcp --dport 22 -m comment --comment "SSH" -j ACCEPT
    -A services -p tcp -m tcp --dport 80 -m comment --comment "HTTP" -j ACCEPT
    -A services -p tcp -m tcp --dport 443 -m comment --comment "HTTPS" -j ACCEPT
    COMMIT
    



The rest of the series will continue to build upon this setup, so this is a good reference point to end this one on. See you again in [Part 2](https://kromey.us/2016/07/setting-up-an-iptables-firewall-part-2-759.html)!
