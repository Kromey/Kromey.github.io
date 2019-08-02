---
author: kromey
comments: true
date: 2009-09-17 01:54:05+00:00
layout: post
link: https://kromey.us/2009/09/trying-some-new-anti-spam-techniques-190.html
redirect_from: /2009/09/trying-some-new-anti-spam-techniques-190.html
slug: trying-some-new-anti-spam-techniques
title: Trying Some new Anti-Spam Techniques
wordpress_id: 190
categories:
- Updates
tags:
- new features
- spam
---

If you've been paying attention to my Akismet counter on the sidebar, you've probably noticed the number trending upwards quite rapidly over the last week. Apparently the spambots have found me.

Akismet's done a superb job of preventing you fine folks from seeing the spam. And WordPress similarly does a superb job of providing a single-click interface to purge all that spam. But I'd really rather not have to be bothered with that.

So I've just implemented a quick-and-dirty plugin that uses [Tornevall](http://dnsbl.tornevall.org/)'s DNSBL service to bar these spambots from posting at all. With any luck none of you will be affected or even notice at all, but do let me know if you find yourself unable to post comments (assuming you have another way of reaching me, that is).

Coincidentally, this is providing a handy lesson in writing WordPress plugins. In the dive-in-headfirst-and-hope-you-can-swim sort of way...
