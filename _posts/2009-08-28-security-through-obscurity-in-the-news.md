---
author: admin
comments: true
date: 2009-08-28 00:53:00+00:00
layout: post
link: https://kromey.us/2009/08/security-through-obscurity-in-the-news-123.html
slug: security-through-obscurity-in-the-news
title: Security Through Obscurity in the News
wordpress_id: 123
categories:
- Security
tags:
- computer
- news
---

Shortly after my [previous post regarding security through obscurity](http://kromey.sd41.net/2009/08/security-through-obscurity-over-demonized-94.html), I spotted an article on ZDNet detailing a [new vulnerability affecting Cisco wireless routers](http://news.zdnet.com/2100-9595_22-334210.html). If not for the reference to "skyjacking" in the title, I would have stopped reading halfway through the article and dismissed the whole thing as nothing more than a spot of sunshine lighting up a "vulnerability" in a network's obscurity.

The first half of that article details how Cisco wireless routers, under certain configurations, will send unencrypted data packets revealing information about the internal network's setup, and specifically giving away the IP of their controller. You can read the article for more information on the issue itself, I'm not rehashing that here; also be sure to read the second half of the article, which details the "skyjack" exploit, which is actually pretty interesting (if you're the kind of person interested in networking equipment's security).

What I am writing about here is to point out the obvious security failing. If all that stands between your wireless controller and a DoS attack is your attacker not knowing the IP of your controller, your security issues go _far_ deeper than this new Cisco vulnerability. Why don't you have access controls preventing a rogue machine connecting to your network in the first place? Why don't you have an IDS or, even better, an IPS to detect and potentially stop a DoS attack? Why don't you have any of the myriad DoS mitigating tools in place to protect your systems?

Don't get me wrong - I'm not saying that preventing a DoS attack is easy, nor am I saying that it's a good thing that Cisco is leaking detailed information about your internal network. In the case of the latter, in fact, it most certainly is a Bad Thing® - as I mentioned in my previous post on this topic, obscurity can be effective as one layer of a more comprehensive security strategy.

What I _am_ pointing out here is that if simply revealing your wireless controller's IP is all that is necessary to allow an attacker to successfully execute a DoS attack, your security strategy relies far too heavily upon obscurity.
