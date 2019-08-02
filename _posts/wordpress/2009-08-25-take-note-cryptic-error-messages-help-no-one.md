---
author: kromey
comments: true
date: 2009-08-25 00:48:30+00:00
layout: post
link: https://kromey.us/2009/08/take-note-cryptic-error-messages-help-no-one-101.html
redirect_from: /2009/08/take-note-cryptic-error-messages-help-no-one-101.html
slug: take-note-cryptic-error-messages-help-no-one
title: 'Take Note: Cryptic Error Messages Help No One'
wordpress_id: 101
categories:
- Tech
tags:
- coding
- errors
- pet peeves
- php
---

I'm a techie. A nerd, if you prefer. When my computers break, I like to fix them. I will spend more hours than most people would consider sane Googling for answers to my current woes rather than take my computer to someone who gets paid to do the same thing (and likely already has, and thus can fix my problem in a fraction of the time).

I'm also a programmer, but at the same time I'm human - that means my code is imperfect. Being that PHP has been my bread-and-butter for the last 5 years or so, and of course the previous sentence's statement that I'm a fallible programmer, I've of course seen this [ever-so-famous error message](http://www.google.com/search?q=T_PAAMAYIM_NEKUDOTAYIM):

    
    Parse error: syntax error, unexpected T_PAAMAYIM_NEKUDOTAYIM in /foo/bar.php on line 42


Take note: If you're providing error messages (and you should be!), make them meaningful to the person reading them!

T_PAAMAYIM_NEKUDOTAYIMs aside, today I was stumped by another cryptic PHP error message. Let me tell you about it.

At work, a customer that I work very closely with has a lot of very specific reporting requirements. Rather than asking us to recreate every report they need (and which they themselves have already created), they instead asked us to provide an export of the raw data so that they could run their own reports. Simple enough: Nightly database dumps, zip 'em up, FTP 'em, done!

Now they want to switch to FTP-SSL. Again, easy enough, all that's required in PHP is to replace the `ftp_connect()` call with `ftp_ssl_connect()` and everything works. In theory, anyway - if there's one thing I've learned working with PHP, it's never to take anything for granted. So I asked that the customer provide some test credentials so that I can make sure it all works just fine.

They oblige, and this morning I set off, armed with the online documentation and GVim, and within a short time I have a test script that connects, logs in, and disconnects. Lo! It works! That really _was_ just that easy!

Now let's do something _really fancy_: let's _list the contents of the directory_!


    
    kromey@vmsys:~/projects$ php ftps_test.php 
    Warning: ftp_get(): php_connect_nonb() failed: Operation now in progress (115) in
    /home/kromey/projects/ftps_test.php on line 27
    
    Warning: ftp_get(): Type set to A. in /home/kromey/projects/ftps_test.php on line 27
    Failed to get file



Wait, what? What's this `php_connect_nonb()` nonsense? And if it failed, how is any operation now in progress?

Googling `php_connect_nonb()` was fruitless - lots of people complaining about lots of different errors produced by the function. None of them matched mine. So I Googled the exact message I got; found some hits, but still no one could explain the problem or offer a resolution.

Fine, let's install ftp-ssl and fire that up, see what it can tell us.


    
    kromey@vmsys:~$ pftp -v ftp.example.com
    Connected to ftp.example.com.
    220 Welcome to Example.com FTP Server.
    Name (ftp.example.com:kromey): kromey_test
    234 AUTH command OK. Initializing SSL connection.
    [SSL Cipher RC4-SHA]
    331 User name okay, need password.
    Password:
    230 User logged in, proceed.
    Remote system type is UNIX.
    Using binary mode to transfer files.
    ftp> ls
    227 Entering Passive Mode (172,20,1,6,195,80)
    ftp: connect: Connection timed out
    ftp> quit
    221 Goodbye!



That 227 message was followed by ~90 seconds of sitting and waiting. So something is wrong, and it's not PHP's fault. But PHP didn't mention anything about a timeout - what's going on here?

The answer lies in the 227 response itself - specifically the string of numbers at the end. Loosely translated, that's a message from the server saying "I'm now listening for your data connection on 172.20.1.6:50000". ([What this means](http://en.wikipedia.org/wiki/Ftp#Connection_methods); note that I'm using "passive mode".) The problem is that that's a non-routable private IP - probably the server's internal IP - and therefore my client, being external from that network, can't get to the server to open that data connection.

Okay, so figuring this out required learning a fair bit about the low-level workings of the FTP protocol. But PHP certainly wasn't helpful here - I wasted a good 2 hours trying to figure out why `php_connect_nonb()`, a function I wasn't calling anywhere in my code, was failing, and what the error message meant. Couldn't they simply have said something like, "Unable to open connection: Operation timed out"?

And I'm still wondering what operation was "in progress" after that error...
