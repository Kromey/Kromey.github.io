---
author: admin
comments: true
date: 2014-03-09 19:53:29+00:00
layout: post
link: https://kromey.us/2014/03/install-dropbox-on-ubuntu-server-12-04-lts-642.html
redirect_from: /2014/03/install-dropbox-on-ubuntu-server-12-04-lts-642.html
slug: install-dropbox-on-ubuntu-server-12-04-lts
title: Install Dropbox on Ubuntu Server 12.04 LTS
wordpress_id: 642
categories:
- How-to
- Tech
tags:
- dropbox
- guide
- linux
- ubuntu
---

I love Dropbox. I've [previously posted](http://kromey.us/2013/11/backing-up-your-stories-with-scrivener-and-dropbox-599.html) about how it can be used to help back up your files. But what about backing up Dropbox itself?

Well, since I happen to have a file server running automated backups, I decided I wanted my Dropbox files backed up on it as well. Unfortunately, setting that up wasn't as easy as it should have been...

First, why would you want to back up your Dropbox? Isn't it itself a backup?

Because of Dropbox's automated nature, anything that corrupts or deletes your files gets quickly synced to all of your computers. Just like that, in an instant, every copy you had across every machine is gone. That doesn't really sound like a "backup", now, does it?

Now, Dropbox does keep versions of your files for 30 days. But if you want longer-term backup protection (without paying for Packrat), or just another layer of security, or you don't trust cloud services to always be there, keeping your own backups is the way to go.

Fortunately, Dropbox's own daemon works just fine from a CLI-only Linux environment such as a server installation. Unfortunately, getting that to run isn't trivial. At least, not without knowing what you have to do. So that's what I'm going to give you here.

Dropbox provides a handy download for their daemon, as well as a nifty Python script for controlling same. Unfortunately, not even the Debian/Ubuntu .deb package properly handles dependencies, nor does running the client without them tell you what's missing. And installing the Dropbox client from the Ubuntu repositories (`sudo apt-get install nautilus-dropbox`) still doesn't get you there. Not to mention that even if this route did work, you'd have a single daemon for the whole system, rather than being able to have per-user daemons running.

Here's the proper procedure:

    
    
    $ sudo apt-get install nautilus
    $ cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
    $ ~/.dropbox-dist/dropboxd
    


Wait a minute. I have to install Nautilus, the GUI file manager, on my GUI-less Linux server? Yes, yes you do. Or, perhaps more accurately, it's probably one (or a few) of the dozens of extra packages that come with it that Dropbox needs. I didn't take the hours and hours of trial and error to find the precise library or set of libraries that actually makes the daemon work; suffice it to say that installing Nautilus got it working.

Once you start up the daemon, it will print a web URL on your console. Copy that into a web browser, and then log into your Dropbox account. That will link your account to this daemon, and it will begin syncing your files. Hit Ctrl-C to stop it, because you want to be able to run this in the background while you use your system, don't you? So let's download Dropbox's control script next:

    
    
    $ wget -O dropbox.py https://www.dropbox.com/download?dl=packages/dropbox.py
    $ chmod +x dropbox.py
    $ ./dropbox.py start
    



Voila! You now have Dropbox running on your GUI-less Linux server! I then went a step further, and moved my Dropbox folder into my Samba file share; this not only gives me another route to access my Dropbox files, but (more to the point) puts them into my server's backup routine so that they get backed up regularly.

    
    
    $ ./dropbox.py stop
    $ mv ~/Dropbox/ /path/to/your/smb/share/
    $ ln -s /path/to/your/smb/share/Dropbox/ ~/Dropbox
    $ ./dropbox.py start
    



Another handy feature of this script is its status output: invoking `./dropbox.py status` will tell you not only that it is in the process of downloading files, but how fast it's going, how many it has left to do, and a (very) rough approximation of how much longer it expects to spend on that. I set `watch` to print out that and to watch the growth of my Dropbox folder (`watch -n30 "./dropbox.py status ; du -sh /path/to/your/smb/share/Dropbox/"`) while I wandered off and prepared dinner.

And an advantage of this process is that (I believe, anyway, I haven't actually tried this yet) I could log into the server as a different user, download the Dropbox client, and link it to a different Dropbox account, and use my single server to back up multiple clients. Shiny!
