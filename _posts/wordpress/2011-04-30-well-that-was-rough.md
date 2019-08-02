---
author: kromey
comments: true
date: 2011-04-30 22:19:58+00:00
layout: post
link: https://kromey.us/2011/04/well-that-was-rough-400.html
redirect_from: /2011/04/well-that-was-rough-400.html
slug: well-that-was-rough
title: Well, that was rough
wordpress_id: 400
categories:
- Updates
tags:
- nginx
- php
- ubuntu
---

Just upgraded my VPS server. Unfortunately, it wasn't smooth, not by a long shot. The usual `do-release-upgrade` got me into quite the pickle, trying to take my out-dated Ubuntu 9.04 server to Ubuntu 9.10. I think a big part of the hassle was due to the way my VPS is hosted here on Linode.

Indeed, to get it to boot again, I had to change the kernel in my configuration profile to match the new kernel (which I had to boot into the Fennix rescue environment to find out what it was). At that point it was working, but I wasn't eager to repeat that with a second `do-release-upgrade` to get onto 10.04 LTS.

So I simply reprovisioned the server, to a fresh 10.04 LTS image straight from Linode's systems. Then things got really interesting...

While I had backed up my databases and web files, I had not documented any of my installation procedures -- a real mess, since I'm using a custom-compiled nginx installation and the oh-so-poorly-documented PHP FastCGI server. Compiling nginx isn't that big a deal, and I got an upgrade in the process (from 0.8.something to 1.0.0), but the dependencies took some work to get taken care of.

For fellow Ubuntu (and probably Debian) users, the dependencies to compile nginx can be installed with `sudo apt-get install g++ libssl-dev libpcre3-dev`.

After that, the next trick was to get PHP's FastCGI server running. Good luck finding documentation for this on php.net! Fortunately it's not really that hard; I have it running on a UNIX socket with the command `php-cgi -b /tmp/php5.socket`.

Took some work getting some usable startup scripts for these two services. Both are actually copied from online sources (not sure if I've still got the original sources to cite, unfortunately). I'll post those later, though, in a more complete write-up on both of these.

**Edit 13 June 2011:** Wish I'd seen [these instructions](http://library.linode.com/troubleshooting/upgrade-to-ubuntu-10.04-lucid) on Linode's website before I started this whole process, might have saved me a lot of work and not a few headaches!
