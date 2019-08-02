---
author: admin
comments: true
date: 2011-04-10 07:13:18+00:00
layout: post
link: https://kromey.us/2011/04/oh-software-raid-how-i-love-you-389.html
redirect_from: /2011/04/oh-software-raid-how-i-love-you-389.html
slug: oh-software-raid-how-i-love-you
title: Oh software RAID, how I love you!
wordpress_id: 389
categories:
- Tech
tags:
- raid
- ubuntu
---

Recently, my file server suffered a hard drive failure. Fortunately, as was the primary _purpose_ of said file server, I had backups and thus lost no data. But, instead of simply replacing the failed disk, I'm taking the opportunity to upgrade and rebuild the thing, and doing a few things differently.

For starters, I'm ditching LVM for MD. While I'm going to continue to rely on my backups to provide safety and redundancy for my files (files will live on a RAID0 array, backups on another, physically separate RAID0 array), I'm now adding mirroring (RAID1) to my system partition.

Software RAID makes it so easy to put two completely different RAID types (RAID0 and RAID1) on the same physical disks. I challenge anyone to find a hardware RAID controller that can do the same thing!

I'll write up another blog post walking through the setup of my newly upgraded and rebuilt server, including details of my RAID setup, after I've completed it. After that, I'll post about my backup scheme (which is also getting updated and upgraded), and maybe get back into semi-regular posting.
