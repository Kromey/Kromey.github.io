---
author: admin
comments: true
date: 2014-03-07 03:14:14+00:00
layout: post
link: https://kromey.us/2014/03/help-my-cron-jobs-arent-running-640.html
redirect_from: /2014/03/help-my-cron-jobs-arent-running-640.html
slug: help-my-cron-jobs-arent-running
title: Help! My cron jobs aren't running!
wordpress_id: 640
categories:
- Tech
tags:
- cron
- fail
- linux
- ubuntu
---

Ugh. I can't count how many times this one's bit me, and frustratingly kept my `cron` scripts from running -- always without error, or notice, or even warning, no matter how many logs I scour!

While it may be different on other systems, Ubuntu at least uses the `run-parts` command to execute scripts in the `/etc/cron.hourly`, `cron.daily`, `cron.weekly`, and `cron.monthly` directories. Which is all well and good.

Unless, like me, you're addicted to file extensions.

All of my shell scripts get a `.sh` file extension. Yeah, I know, not necessary in Linux, but I find it useful to be able to tell at a quick glance at the output of `ls` exactly what I'm looking at.

Unfortunately, by default, `run-parts` will _only_ include scripts whose names contain _only_ letters (upper- or lower-case), numbers, underscores, and hyphens. Put a period and a file extension on your script? Won't be picked up by `run-parts`, and therefore won't be executed by your `cron`.

Fortunately, it's an easy fix: `scriptname.sh` just becomes `scriptname`. I just wish there were some feedback in the logs telling me why a script is being skipped entirely, because I forget about this _every single time I write a new script!_
