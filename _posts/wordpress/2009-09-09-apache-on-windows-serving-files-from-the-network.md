---
author: kromey
comments: true
date: 2009-09-09 01:44:49+00:00
layout: post
link: https://kromey.us/2009/09/apache-on-windows-serving-files-from-the-network-150.html
redirect_from: /2009/09/apache-on-windows-serving-files-from-the-network-150.html
slug: apache-on-windows-serving-files-from-the-network
title: 'Apache on Windows: Serving Files From the Network'
wordpress_id: 150
categories:
- How-to
- Tech
tags:
- apache
- guide
- linux
- windows
---

Recently I had a problem: Without going into the "whys" here, I found myself on a Windows XP system needed to parse and serve PHP files in Apache from a network share. Sounds easy enough, right? Unfortunately, the obvious answer didn't work, and hours of Googling turned up countless suggestions, most of which didn't work at all. I even found some very detailed step-by-step instructions that turned out to be based upon a premise that doesn't work at all.

As it turns out, this is a problem with a very simple, yet unobvious, solution, and today I will share it with you. With any luck, Google will start serving up this post to others looking to serve files in Apache on Windows from a network file share.

My specific goal was to share a project directory on my Linux development system to be run on my Windows XP testing system; for reasons beyond the scope of this post, the Windows XP system is where my Apache server is running. I made my project directory available on the network as an SMB share at `\\server\project`; I wanted an alias configured to redirect the `/p` virtual directory to my project directory, which I mapped as a network drive to `Y`. My first attempt was simple:

    
    Alias /p Y:/project


But Apache just threw a 404 error when attempting to access anything under that directory. Adding a Directory block for that network drive didn't work either - instead, Apache threw an error when trying to restart.

I spent hours Googling this problem, reasoning that I'm not the only person who needed to do this. I found tons of suggestions ranging from "Map the network drive" (which I just did, with no success) to "Mount the share within your NTFS file system on C" (which, following the step-by-step directions provided by the helpful user, failed to work at all).

Finally, I hit upon the solution: Use the UNC path instead of the network drive letter. Now my Apache config looks like this (abbreviated for clarity):

    
    DocumentRoot "C:/web/htdocs"
    <Directory "C:/web/htdocs">
        Options None
    </Directory>
    Alias /p //server/project
    <Directory //server/project>
        Options Indexes
    </Directory>


Apache now very happily serves files from this network share without batting an eye. Why this very simple solution was so hard to find is completely mind-boggling. The internet seems to be littered with useless and false information for this problem, so here's my feeble attempt to provide some quality aid to those who find themselves in the same pickle.
