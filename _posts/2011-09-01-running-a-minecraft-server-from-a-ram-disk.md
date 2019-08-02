---
author: admin
comments: true
date: 2011-09-01 03:16:29+00:00
layout: post
link: https://kromey.us/2011/08/running-a-minecraft-server-from-a-ram-disk-452.html
redirect_from: /2011/08/running-a-minecraft-server-from-a-ram-disk-452.html
slug: running-a-minecraft-server-from-a-ram-disk
title: Running a Minecraft Server from a RAM Disk
wordpress_id: 452
categories:
- How-to
- Tech
tags:
- guide
- linux
- minecraft
---

RAM is fast. Very fast. Very, _very_ fast. If you were to think of your hard drive as a Ferrari, your RAM would be a tachyon -- a theoretical particle that moves faster than the speed of light!

That's great, but what does it have to do with Minecraft? Well, everything, actually!

Minecraft sees a lot of hard disk I/O, especially if the players on your server like to wander or explore. But we already know that your hard disk is slow. Wouldn't it be great if we could upgrade from that slow little Ferrari and instead ride the tachyon?

Well, you can!

As the tags on this post suggest, we're targeting a Linux system running the Minecraft server. Windows and Mac both can do the same thing, but the method is quite different and won't be discussed here; if I get bored someday, I may write a follow-up post adapting this approach for those systems.

But for now, these are the prerequisites you need:



	
  * A computer running Linux to host your Minecraft server

	
  * The Minecraft server software

	
  * `rsync`



Strictly speaking, you could actually use good ol' `cp` instead of `rsync`, but the latter will help us be more efficient.

The first thing you have to do is create your RAM disk. We'll be using `tmpfs` to accomplish this, and we'll be putting it into `fstab` to ensure we always have it, every time the system boots up. You have to make sure that you make this file system larger than your current needs (for me, a somewhat large-ish world plus the server files takes up 91 MB), but smaller than your available RAM; in this example, I'm creating a 128 MB RAM disk by adding the following line to `/etc/fstab`:


    
    
    tmpfs /srv/mc tmpfs size=128M 1 1
    



Of course, we also have to create the target folder, in my example `/srv/mc`.

But wait! you say? Can't we just use the defaults and let the file system be half our total RAM? you ask?

Well, certainly! And if that's what you want to do, then by all means do it -- just replace `size=128M` above with `defaults`. The catch with this approach -- and the reason I instead specified a smaller size -- is that if your Minecraft world grows too large, you can easily see it gobbling up your computer's RAM, and before you know it it's eating swap like candy and performance just tanks! You can avoid that by keeping an eye on your server's disk usage, of course, but I like having hard limits that force me to address pending problems -- running out of disk space being a very obvious hard limit!

Alright, now we have our RAM disk configured; you can either reboot now, or simply run the command `mount -a` in your terminal to mount your new `tmpfs` file system.

So, we're ready to go, right? Just dump your Minecraft files into there and start 'er up, right?

Sadly, no, it's not quite that simple. While RAM certainly is very fast, it's also volatile -- anything sitting in our RAM disk when the computer loses power or restarts will be irrecoverably gone forever. Most likely, you want to keep your Minecraft world around a little longer than just until the next reboot. So we need to make this persistent somehow.

This is where `rsync` is going to come in. When we first start Minecraft, we first have to copy all the files from somewhere on disk into our new file system; when we stop Minecraft, we have to copy any changes back out to disk; and finally, we want to periodically copy those changes out to disk, just in case a power outage or other unexpected incident kills our server.

The first and second are simple: Simply modify whatever script or command you use to start/stop your server to first `rsync` your server files:


    
    
    #Start action
    rsync -a --delete-after /path/to/minecraft/files/ /srv/mc/
    start-minecraft
    
    #Stop action
    stop-minecraft
    rsync -a --delete-after /srv/mc/ /path/to/minecraft/files/
    



Simple enough. The tricky part is periodically saving server changes. You wouldn't think it was tricky -- just cron the "stop" `rsync` command to run every 15 minutes or so -- but you'd miss anything the server hasn't yet written to the disk. Ideally, you want to save everything in the whole world -- including changes to chunks currently in memory, which Minecraft doesn't usually write to disk until the chunk is unloaded from memory. The Minecraft server console includes a save-all command that writes _everything_ out to disk, but unfortunately that's difficult to script, since there's no interaction with the server except the console itself.

Fortunately, if you run your Minecraft server in a `screen` session, you can `stuff` commands into the console, which allows you to send this save-all command:


    
    
    screen -p 0 -S minecraft -X eval 'stuff "save-all"\015'
    rsync -a --delete-after /srv/mc/ /path/to/minecraft/files/
    



I won't go into what this `screen` command does here, though; I'll save that for another day, another blog post, where I'll also discuss methods for starting and stopping the server effectively. If you don't have `screen`, or you aren't using it to run your Minecraft server, then you'll have to be happy with only being able to save what Minecraft has decided to commit to the disk; while this won't cause problems as far as typical usage goes, it does increase the likelihood of losing a good chunk of your players' hard work if the server goes down unexpectedly for some reason.

I have this scheduled to run every 15 minutes, but only if the Minecraft server is running; you could inadvertently delete your whole world if you run this and for some reason the RAM disk is empty! Detecting if the server is running is another topic I'll discuss later, in another post.

Until then, you have the building blocks you need to take an already-running Minecraft server, and run it safely and effectively from a RAM disk on your Linux system. So go, and happy mining and crafting!
