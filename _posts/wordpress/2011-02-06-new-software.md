---
author: kromey
comments: true
date: 2011-02-06 04:38:05+00:00
layout: post
link: https://kromey.us/2011/02/new-software-339.html
redirect_from: /2011/02/new-software-339.html
slug: new-software
title: New Software
wordpress_id: 339
categories:
- Updates
tags:
- apache
- nginx
- php
- php-fpm
---

The server's running on new software now. Replaced Apache with [nginx](http://nginx.org/en/), and am now using PHP via [PHP-FPM](http://www.php.net/manual/en/install.fpm.php). I may remove the latter, though, in favor of just the basic FastCGI interface -- this isn't exactly a high-traffic site, so doesn't really need FPM per se.

I'll go into more details in another post. So far, though, I'm very happy -- maybe it's just me, but I really think I actually notice the difference in the site's performance.

I figure it's a good time to also play with the site's theme and layout. So far, though, I've not found a theme that looks good and doesn't make my code snippets look like crap.
