---
author: kromey
comments: true
date: 2011-06-08 02:13:20+00:00
layout: post
link: https://kromey.us/2011/06/named-based-virtual-hosts-with-nginx-on-ipv6-423.html
redirect_from: /2011/06/named-based-virtual-hosts-with-nginx-on-ipv6-423.html
slug: named-based-virtual-hosts-with-nginx-on-ipv6
title: Name-Based Virtual Hosts With nginx on IPv6
wordpress_id: 423
categories:
- How-to
- Tech
tags:
- guide
- ipv6
- linux
- networking
- nginx
---

[Linode.com](http://www.linode.com/?r=87f29c23fd8ce18fdc75ad888998a679311edfca) has recently [added native IPv6 support](http://blog.linode.com/2011/05/03/linode-launches-native-ipv6-support/) to many of its data centers. Linode hosts the VPS that runs this blog, and it happens to reside in their Dallas data center. I was busy planning my wedding when IPv6 support reached me here, so I only got around to enabling it this week.

So now this blog is available over both IPv4 and IPv6, with a special IPv6-only version running at [ipv6.kromey.us](http://ipv6.kromey.us/). It took a bit of doing, and a lot of trial-and-error, so let me save you some time by sharing how I succeeded.

From reading the documentation and the various posts around the internet, it first seemed that I needed to add `listen [::]:80 ipv6only=on` to each of my virtual hosts. This, however, resulted in nginx complaining that the socket was already in use when I tried to do this with more than one of my vhosts. Much tinkering later, and I got it finally worked out.

Before I show you the answer, though, a word of caution: From reading the documentation, I believe that this solution will _not_ work on BSD-based systems, nor will it work on certain Linux-based systems where `net.ipv6.bindv6only` parameter has been changed from the default. Specifically, the solution I am posting here relies upon your networking stack using **hybrid** ports instead of **separate** ports for IPv6 and IPv4; that is, opening a **hybrid** port will accept traffic on both IPv4 _and_ IPv6, whereas you would have to explicitly open **separate** ports for each version of the protocol. However, adapting this hybrid port-based solution to a separate port-based system is trivial, and I'll show that, too.

Now, without further ado, here is how to get nginx running your name-based virtual hosts over IPv6:

**Step 1:** [Enable IPv6 in nginx](http://kovyrin.net/2010/01/16/enabling-ipv6-support-in-nginx/) if you haven't already. Nothing tricky here, except to make sure that if you have to recompile your server, you remember to include any of your own configure parameters that you need.

**Step 2:** In your default virtual host, change your `listen 80 default_server;` directive to `listen [::]:80 default_server;`. This relies upon your system using those **hybrid** ports I mentioned earlier to automatically open the same port on IPv4 as well (even though `netstat` doesn't show that). (If you are not using a default virtual host, skip this step.)

**Step 3:** In all of your other virtual hosts, change your `listen 80;` directives to `listen [::]:80;`. If you had previously omitted the `listen 80;` directive (since that's the default if not specified), you must now add the `listen [::]:80;` directive.

Note that you can do exactly the same thing with additional ports -- I additionally have `listen [::]:8080 default_server;` in my default vhost, and `listen [::]:8080` in my vhost that listens on that port.

Okay, but what about you folks on systems that are using **separate**, not **hybrid**, ports? Well, you simply have to specify IPv4 and IPv6 `listen` directives, and add the parameter `ipv6only=on` to one of your IPv6 declarations for each port. So _in addition_ to `listen 80 default_server;` in your default vhost, you would _add_ `listen [::]:80 default_server ipv6only=on;`. Yes, I'm heavily stressing that this is _added_ -- if you have separate ports, you have to explicitly open one on each protocol. (If you are not using a default vhost, then you have to add a `listen [::]:80 ipv6only=on;` to _precisely one_ of your vhosts; see below for more explanation on this point.)

Then, in each of your vhosts, you would _add_ `listen [::]:80;` where you have `listen 80;`, but note that I did _not_ specify `ipv6only=on` again -- this must be specified _once and only once_, or else nginx will throw errors about the port already being in use.

And, again, you can do this for any and all ports you wish to use, remember that `ipv6only=on` must be specified _once and only once_ for each port.

Much thanks and many kudos go to kolbyjack on Server Fault for [helping me figure this out](http://serverfault.com/q/277653/76504).
