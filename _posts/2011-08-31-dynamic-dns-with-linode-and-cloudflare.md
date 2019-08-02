---
author: admin
comments: true
date: 2011-08-31 01:45:38+00:00
layout: post
link: https://kromey.us/2011/08/dynamic-dns-with-linode-and-cloudflare-459.html
redirect_from: /2011/08/dynamic-dns-with-linode-and-cloudflare-459.html
slug: dynamic-dns-with-linode-and-cloudflare
title: Dynamic DNS with Linode and CloudFlare
wordpress_id: 459
categories:
- How-to
- Tech
tags:
- cloudflare
- dns
- dynamic dns
- guide
- linode
- linux
---

[Linode](http://www.linode.com/?r=87f29c23fd8ce18fdc75ad888998a679311edfca) is a great provider of Linux-based VPS -- this site is running from one right now, in fact! To help support it, and for a tad of extra security, I also use the free [CloudFlare](http://www.cloudflare.com/) service, which provides a security-centric CDN aimed at protecting your site from bots.

Both of these services have their own included DNS managers. And both provide an API that lets you manipulate those DNS records programmatically.

This brief post will show you how to leverage these services to quickly and easily roll your own dynamic DNS service.

If you're like most people -- including me -- then your home internet connection doesn't provide a static IP address. If you're like much fewer people -- including me -- you have remote services running from your home internet connection. But running services from a dynamic IP address can be problematic, as you can't be sure that the IP you had yesterday is the same one you have today.

That's where dynamic DNS services come in. Used to be I used DynDNS for mine, but with the quick tricks I'm going to show you now, I use Linode and CloudFlare, which host my static DNS as well, directly.

First up is Linode. First thing you need to do is create the record you'll be updating in the DNS manager; once it's there, you can update it with this request:


    
    
    https://api.linode.com/?api_key=your-linode-api-key&api_action=domain.resource.update&domainid=12345&resourceid=12345&target=[remote_addr]
    



Pretty simple. You can find your API key in your account page on Linode. The trick with this one is that you first have to use the `domain.list` API command to find the `domainid`, and then the `domain.resource.list` API command to find the `resourceid`. Not terribly difficult -- I did it in my browser in about a minute or two -- but it is a bit awkward. Still, it works.

The really great thing about Linode's API is the `target=[remote_addr]` bit at the end. This obviates the need to use a second command to get your IP address -- it tells Linode to quite simply use what IP address is accessing the API as the new target for the A record you are updating.

That's Linode down. Now let's do CloudFlare. Again, you first have to create the record, but once that's done it's as simple as:


    
    
    https://www.cloudflare.com/api.html?a=DIUP&hosts=dyn.example.com&u=user@example.com&tkn=your-cloudflare-api-key&ip=123.123.123.123
    



Well, we're both simpler and more complicated, here. Again, you'll need to get your API token from your account page on CloudFlare. Once you have that, the simpler part is the `hosts` key: this is, quite simply, the A record you want to update. A lot easier than tracking down a domain ID and then a domain resource ID, eh? But then comes the complicated part: CloudFlare's API doesn't support a `[remote_addr]` value like Linode does, so we have to get our own IP ourselves. The easiest way is with another request:


    
    
    http://automation.whatismyip.com/n09230945.asp
    

**Update: WhatIsMyIP's API is now behind user registration. You can either sign up to use their API, or substitute an alternative such as https://api.ipify.org.**



That returns just the IP address of your request and nothing more. You can easily combine these two -- assuming you're using Bash -- like so:


    
    
    wget -qO- https://www.cloudflare.com/api.html?a=DIUP\&hosts=dyn.example.com\&u=user@example.com\&tkn=your-cloudflare-api-key\&ip=`wget -qO- http://automation.whatismyip.com/n09230945.asp`
    



**Note the escaping `\` characters on all the ampersands!** It quite simply won't work if you don't escape them.

Now we can put them all together, and add them to a cron job; I run it every 30 minutes, which is more than enough to keep it updated. If you run it more frequently, just be sure you're not running afoul of the respective API usage limits -- for example, CloudFlare doesn't want you doing more than 300 API requests (total) per hour, and WhatIsMyIP doesn't want you making a request more frequently than once every 5 minutes (300 seconds).

My job looks roughly like this [line breaks added for readability]:


    
    
    /bin/echo `/bin/date`:
     `/usr/bin/wget -qO-
     https://api.linode.com/?api_key=your-linode-api-key
      \&api_action=domain.resource.update
      \&domainid=12345\&resourceid=12345
      \&target=[remote_addr]`
     >> /var/log/linode_dyndns.log
    
    /bin/echo `/bin/date`:
     `/usr/bin/wget -qO-
     https://www.cloudflare.com/api.html?a=DIUP
      \&hosts=dyn.example.com
      \&u=user@example.com
      \&tkn=your-cloudflare-api-key
      \&ip=\`/usr/bin/wget -qO-
       http://automation.whatismyip.com/n09230945.asp\``
     >> /var/log/cloudflare_dyndns.log
    



This gives me a pair of nicely formatted logs, with each line time-stamped. Well, almost nicely formatted -- the Linode API returns a JSON object, which as you can see I don't bother to parse. Mostly because it's plenty readable by human eyes anyway, so why bother?
