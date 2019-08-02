---
author: admin
comments: true
date: 2016-07-18 17:11:35+00:00
layout: post
link: https://kromey.us/2016/07/blocking-httpoxy-requests-in-nginx-747.html
redirect_from: /2016/07/blocking-httpoxy-requests-in-nginx-747.html
slug: blocking-httpoxy-requests-in-nginx
title: Blocking httpoxy Requests In nginx
wordpress_id: 747
categories:
- Security
- Tech
tags:
- guide
- how-to
- httpoxy
- nginx
- Security
---

With the [httpoxy vulnerability](https://httpoxy.org/) making headlines in the security circles right now, I decided to get more aggressive in guarding my own sites against it, specifically by outright blocking any such requests. Turns out, it's not hard to do at all!

My first approach was to simply "erase" the Proxy header from any requests that may include it. While the httpoxy page shows [how to do this in your `fastcgi_params` file](https://httpoxy.org/#fix-now), I took it a step further and added the following line to my `http` block:


    
    
    proxy_set_header Proxy "";
    



While this would be effective in stopping the attack (even against services that may not use my `fastcgi_params` file), I wanted to get more aggressive: The Proxy header has no business being in legitimate requests at all, so I wanted to outright block those requests altogether.

Turns out this was pretty simple as well:


    
    
    if ($http_proxy) {
        return 403 
            "<html>
    <head>
    <title>403 Proxy Header Not Allowed</title>
    </head>
    <body style="background-color:red;color:white;">
    <center><h1>Proxy Header Not Allowed</h1></center>
    <center><a href="https://httpoxy.org/">httpoxy vulnerability information</a></center>
    </body>
    </html>
    ";
    }
    



Notice that I did take the time to produce an informative response to end users who might see this message; while I don't expect anyone to see it except would-be hackers and script kiddies trying to exploit it (and, thus, who already know about it), it doesn't hurt just in case someone who isn't expecting this does happen to see it.

For this to work, though, it has to be within your `server` block for each host you want to protect; fortunately for me, I already have a snippet of `default_locations` that I `include` into every host's server block, so I added this snippet to that file and one quick reload later _all_ of my hosts are now protected.

Of course, following the principles of "Defense-In-Depth", I _also_ follow the recommendation of the httpoxy page in not passing the header through via my `fastcgi_params` file.
