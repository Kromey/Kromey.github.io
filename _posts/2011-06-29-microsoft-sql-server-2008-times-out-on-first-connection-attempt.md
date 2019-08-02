---
author: admin
comments: true
date: 2011-06-29 02:32:24+00:00
layout: post
link: https://kromey.us/2011/06/microsoft-sql-server-2008-times-out-on-first-connection-attempt-447.html
redirect_from: /2011/06/microsoft-sql-server-2008-times-out-on-first-connection-attempt-447.html
slug: microsoft-sql-server-2008-times-out-on-first-connection-attempt
title: Microsoft SQL Server 2008 Times Out on First Connection Attempt?
wordpress_id: 447
categories:
- How-to
tags:
- sql server
- windows
---

A bizarre issue solved today:

On one server, we're running two (named) instances of Microsoft SQL Server 2008. The first one, using the default instance name, runs just fine with no problems. The second one, however, had a bizarre issue: The first time any application tried to connect, it would simply time out, but if you re-tried _without closing or restarting that application_, it would immediately connect successfully!

What could possibly cause that sort of intermittent error?

My first thought was memory: that server is constantly running at about 90% RAM usage, and an initial delay would make sense if the second SQL Server instance -- which wasn't being regularly used -- was getting swapped out to disk, because it would take time to load it back into RAM, potentially allowing a connection to timeout while waiting, but then work just fine once it's back in RAM.

But that theory fell apart completely when I noticed that the behavior existed _per application instance_, meaning that I could launch e.g. SQL Server Management Studio, connect (on the second attempt), and while I'm using it someone else could get the identical initial-timeout-then-subsequent-successful-connection behavior -- exactly the opposite of what you'd expect if swapping was the problem!

Now I was at a loss. It clearly wasn't a port configuration or firewall error, because I _could_ connect, without changing any settings. And it wasn't a swapped-to-disk issue, because even while it was in use it would generate the exact same behavior for new connection attempts.

So what could it be?

Well, it turns out that it was, in fact, a firewall issue! Digging through the TCP/IP Properties for the instance in SQL Server Configuration Manager -- looking for something silly like a "fail initially" setting set to "Yes" -- I suddenly noticed that the IPAll section was using a "dynamic" TCP port of 59196 -- which the firewall was blocking! Opening that port in the firewall immediately solved the problem! (By the way, can anyone tell me what's so "dynamic" about a single TCP port?)

I changed the settings to use a "regular" TCP port, setting it to 1432 (while the default instance is using the default port 1433), modified the firewall to allow that port, and _voila!_ It works now!

Why the firewall blocking this instance's port would only cause the _first_ connection attempt to fail is still beyond me...
