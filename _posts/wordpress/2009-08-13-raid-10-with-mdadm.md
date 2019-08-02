---
author: kromey
comments: true
date: 2009-08-13 00:55:33+00:00
layout: post
link: https://kromey.us/2009/08/raid-10-with-mdadm-65.html
redirect_from: /2009/08/raid-10-with-mdadm-65.html
slug: raid-10-with-mdadm
title: RAID 10 with mdadm
wordpress_id: 65
categories:
- How-to
- Tech
tags:
- guide
- linux
- raid
- ubuntu
---

If I had to pick one fault of Linux, it would be that for almost everything, the Linux user is inundated with hundreds of possible solutions. This is both a blessing and a curse - for the veterans, it means that we can pick the tool that most matches how we prefer to operate; for the uninitiated, it means that we're so overwhelmed with options it's hard to know where to begin.

One exception is software RAID - there's really only one option: `mdadm`. I can already hear the LVM advocates screaming at me; no, I don't have any problem with LVM, and in fact I do use it as well - I just see it as filling a different role than `mdadm`. I won't go into the nuances here - just trust me when I say that I use and love both.

There are quite a few how-tos, walkthroughs, and tutorials out there on using `mdadm`. None that I found, however, came quite near enough to what I was trying to do on my newest computer system. And even when I did get it figured out, the how-tos I read failed to mention what turned out to be a very critical piece of information, the lack of which almost lead to me destroying my newly-created array.

So without further ado, I will walk you through how I created a storage partition on a RAID 10 array using 4 hard drives (my system boots off of a single, smaller hard drive).

The first thing you want to do is make sure you have a plan of attack: What drives/partitions are you going to use? What RAID level? Where is the finished product going to be mounted?

One method that I've seen used frequently is to create a single array that's used for everything, including the system. There's nothing wrong with that approach, but here's why I decided on having a separate physical drive for my system to boot from: simplicity. If you want to use a software RAID array for your boot partition as well, there are plenty of resources telling you how you'll need to install your system and configure your boot loader.

For my setup, I chose a lone 80 GB drive to house my system. For my array, I selected four 750 GB drives. All 5 are SATA. After I installed Ubuntu 9.04 on my 80 GB drive and booted into it, it was time to plan my RAID array.

    
    kromey@vmsys:~$ ls -1 /dev/sd*
    /dev/sda
    /dev/sdb
    /dev/sdc
    /dev/sdd
    /dev/sde
    /dev/sde1
    /dev/sde2
    /dev/sde5


As you can probably tell, my system is installed on `sde`. While I would have been happier with it being labeled `sda`, it doesn't really matter. `sda` through `sdd` then are the drives that I want to combine into a RAID.

`mdadm` operates on _partitions_, not raw devices, so the next step is to create partitions on my drives. Since I want to use each entire drive, I'll just create a single partition on each one. Using `fdisk`, I choose the fd (Linux raid auto) partition type and create partitions using the entire disk on each one. When I'm done, each drive looks like this:

    
    kromey@vmsys:~$ sudo fdisk -l /dev/sda
    
    Disk /dev/sda: 750.1 GB, 750156374016 bytes
    255 heads, 63 sectors/track, 91201 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Disk identifier: 0x00000000
    
       Device Boot      Start         End      Blocks   Id  System
    /dev/sda1               1       91201   732572001   fd  Linux raid autodetect


Now that my partitions are in place, it's time to pull out `mdadm`. I won't re-hash everything that's in the `man` pages here, and instead just demonstrate what I did. I've already established that I want a RAID 10 array, and setting that up with `mdadm` is quite simple:

    
    kromey@vmsys:~$ sudo mdadm -v --create /dev/md0 --level=raid10 --raid-devices=4 /dev/sda1 /dev/sdb1 /dev/sdc1 /dev/sdd1


**A word of caution**: `mdadm --create` will return immediately, and for all intents and purposes will look like it's done and ready. It's not - it takes time for the array to be synchronized. It's probably usable before then, but to be on the safe side wait until it's done. My array took about 3 hours (give or take - I was neither watching it closely nor holding a stopwatch!). Wait until your `/proc/mdstat` looks something like this:

    
    kromey@vmsys:~$ cat /proc/mdstat
    Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
    md0 : active raid10 sdb1[1] sda1[0] sdc1[2] sdd1[3]
          1465143808 blocks 64K chunks 2 near-copies [4/4] [UUUU]


**Edit:** As Jon points out in the comments, you can `watch cat /proc/mdstat` to get near-real-time status and know when your array is ready.

That's it! All that's left to do now is create a partition, throw a filesystem on there, and then mount it.

    
    kromey@vmsys:~$ sudo fdisk /dev/md0
    kromey@vmsys:~$ sudo mkfs -t ext4 /dev/md0p1
    kromey@vmsys:~$ mkdir /srv/hoard
    kromey@vmsys:~$ sudo mount /dev/md0p1 /srv/hoard/


Ah, how sweet it is!

    
    kromey@vmsys:~$ df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/sde1              71G  3.6G   64G   6% /
    tmpfs                 3.8G     0  3.8G   0% /lib/init/rw
    varrun                3.8G  116K  3.8G   1% /var/run
    varlock               3.8G     0  3.8G   0% /var/lock
    udev                  3.8G  184K  3.8G   1% /dev
    tmpfs                 3.8G  104K  3.8G   1% /dev/shm
    lrm                   3.8G  2.5M  3.8G   1% /lib/modules/2.6.28-14-generic/volatile
    /dev/md0p1            1.4T   89G  1.2T   7% /srv/hoard


Now comes the gotcha that nearly sank me. Well, it wouldn't have been a total loss, I'd only copied data from an external hard drive to my new array, and could easily have done it again.

Everything I read told me that Debian-based systems (of which Ubuntu is, of course, one) were set up to automatically detect and activate your `mdadm`-create arrays on boot, and that you don't need to do anything beyond what I've already described. Now, maybe I did something wrong (and if so, please leave a comment correcting me!), but this wasn't the case for me, leaving me without an assembled array (while somehow making `sdb` busy so I couldn't manually assemble the array except in a degraded state!) after a reboot. So I had to edit my `/etc/mdadm/mdadm.conf` file like so:

    
    kromey@vmsys:~$ cat /etc/mdadm/mdadm.conf
    # mdadm.conf
    #
    # Please refer to mdadm.conf(5) for information about this file.
    #
    
    # by default, scan all partitions (/proc/partitions) for MD superblocks.
    # alternatively, specify devices to scan, using wildcards if desired.
    #DEVICE partitions
    
    # auto-create devices with Debian standard permissions
    CREATE owner=root group=disk mode=0660 auto=yes
    
    # automatically tag new arrays as belonging to the local system
    HOMEHOST 
    
    # instruct the monitoring daemon where to send mail alerts
    MAILADDR root
    
    # definitions of existing MD arrays
    DEVICE /dev/sd[abcd]1
    
    ARRAY /dev/md0 super-minor=0
    
    # This file was auto-generated on Mon, 03 Aug 2009 21:30:49 -0800
    # by mkconf $Id$


It certainly _looks_ like my array should have been detected and started when I rebooted. I commented-out the default DEVICES line and added an explicit one, then added an explicit declaration for my array; now it's properly assembled when my system reboots, which means the `fstab` entry doesn't provoke a boot-stopping error anymore, and life is all-around happy!

**Update 9 April 2011:** In preparation for a server rebuild, I've been experimenting with `mdadm` quite a bit more, and I've found a better solution to adding the necessary entries to the `mdadm.conf` file. Actually, two new solutions:



	
  1. Configure your RAID array during the Ubuntu installation. Your `mdadm.conf` file will be properly updated with no further action necessary on your part, and you can even have those nice handy `fstab` entries to boot!

	
  2. Run the command `mdadm --examine --scan --config=mdadm.conf >> /etc/mdadm/mdadm.conf` in your terminal. Then, open up `mdadm.conf` in your favorite editor to put the added line(s) into a more reasonable location.



On my new server, I'll be following solution (1), but on my existing system described in this post, I have taken solution (2); my entire file now looks like this:

    
    kromey@vmsys:~$ cat /etc/mdadm/mdadm.conf
    # mdadm.conf
    #
    # Please refer to mdadm.conf(5) for information about this file.
    #
    
    # by default, scan all partitions (/proc/partitions) for MD superblocks.
    # alternatively, specify devices to scan, using wildcards if desired.
    DEVICE partitions
    
    # auto-create devices with Debian standard permissions
    CREATE owner=root group=disk mode=0660 auto=yes
    
    # automatically tag new arrays as belonging to the local system
    HOMEHOST 
    
    # instruct the monitoring daemon where to send mail alerts
    MAILADDR root
    
    # definitions of existing MD arrays
    ARRAY /dev/md0 level=raid10 num-devices=4 UUID=46c6f1ed:434fd8b4:0eee10cd:168a240d
    
    # This file was auto-generated on Mon, 03 Aug 2009 21:30:49 -0800
    # by mkconf $Id$


Notice that I'm again using the default DEVICE line, and notice the new ARRAY line that's been added. This seems to work a lot better -- since making this change, I no longer experience the occasional (and strange) "device is busy" errors during boot (always complaining about /dev/sdb for some reason), making the boot-up process just that much smoother!
