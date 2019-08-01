---
author: admin
comments: true
date: 2011-06-14 02:01:39+00:00
layout: post
link: https://kromey.us/2011/06/move-an-svn-repository-from-one-server-to-another-433.html
slug: move-an-svn-repository-from-one-server-to-another
title: Move an SVN Repository From One Server to Another
wordpress_id: 433
categories:
- How-to
tags:
- guide
- subversion
- svn
---

There's certainly no shortage of sites offering quick instructions to move your SVN repository from one server to another. [About 3.3 million](http://www.google.com/search?q=move+svn+repository) (at the time of this writing) of them, it seems. So why do I have to make it 3.3 million and 1?

Because they all seem to leave off an important step: What to do on the client side after you've moved the repository on the server side.

Making the move is pretty simple: Log into your server, then use the `svnadmin` tool to dump the repository:


    
    
    $ svnadmin dump /path/to/repo > reponame.dump
    



Simple, eh? And it works on Windows, *nix, whatever, the same way, even moving from one OS to another -- the only requirement is that Subversion runs on it. Now just compress that file and send it along to your new server in whatever way suits you.

Loading it on the other end is just as easy; after decompressing the dump file on the new server:


    
    
    $ svnadmin create /path/to/new/repo
    $ svnadmin load /path/to/new/repo < reponame.dump
    



Nothing to it!

This is where all the other 3.3 million Google hits out there seem to stop. But not me. Let's update our clients to point to the new location of our repo:


    
    
    $ svn switch --relocate http://newdomain.com/path/to/repo /path/to/working/copy
    



If you're using the TortoiseSVN client, right-clicking on the root of your working copy and going to "TortoiseSVN > Relocate..." will bring up a window where you type in the new URL. Other graphical clients I'm sure have similar options.

When using `relocate`, however, you must be very careful to only change from one directory to the **same directory on the new URL**. While the `switch` operation is indeed handy for switching back and forth between branches, tags, and trunk, you must not combine this usage with the `--relocate` option, or else Very Bad Things® will happen and you will most likely have to deleted your working copy and check out a fresh one.
