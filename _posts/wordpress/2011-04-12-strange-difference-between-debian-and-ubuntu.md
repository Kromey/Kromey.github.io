---
author: admin
comments: true
date: 2011-04-12 01:11:57+00:00
layout: post
link: https://kromey.us/2011/04/strange-difference-between-debian-and-ubuntu-391.html
redirect_from: /2011/04/strange-difference-between-debian-and-ubuntu-391.html
slug: strange-difference-between-debian-and-ubuntu
title: Strange Difference Between Debian and Ubuntu
wordpress_id: 391
categories:
- Tech
tags:
- debian
- ubuntu
---

While setting up my file server, I encountered an odd difference in what I was seeing on my Ubuntu server, versus what I was told works perfectly on Debian. Specifically, on the latter, you can `mount --bind` a directory and make it read-only at the same time, but on Ubuntu `mount --bind` explicitly cannot change the mount options, and the same operation (`mount -o bind,ro ...`) requires two distinct commands (`mount --bind ... && mount -o remount,ro ...`)!

I know Ubuntu isn't Debian, but it is based on it! Sure, it does things "the Ubuntu way", which isn't necessarily "the Debian way", but you would expect a low-level utility like `mount` -- especially one that is common across _all_ the *nixes! -- to behave basically the same between Ubuntu and its spiritual (if not actual) upstream Debian. So very strange that it would not, very strange indeed...

Will post about my file server build and setup (including this very odd discovery) later. Just wanted to share this confusion and ask if anyone knows of any other odd differences between Debian and Ubuntu, or know of the reason for this one.
