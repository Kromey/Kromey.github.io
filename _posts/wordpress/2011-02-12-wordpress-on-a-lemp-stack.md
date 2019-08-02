---
author: kromey
comments: true
date: 2011-02-12 04:59:03+00:00
layout: post
link: https://kromey.us/2011/02/wordpress-on-a-lemp-stack-366.html
redirect_from: /2011/02/wordpress-on-a-lemp-stack-366.html
slug: wordpress-on-a-lemp-stack
title: WordPress on a LEMP Stack
wordpress_id: 366
categories:
- How-to
- Tech
tags:
- lemp
- nginx
- php fastcgi
- wordpress
---

For years, I've run everything web-based on the standard LAMP (or, on occasion, WAMP) stack. I never really thought much about it, to tell you the truth: It's what everyone seemed to be using, and it worked, so why question it?

When my server began to frequently encounter out-of-memory errors, it took me a while to come up with the solution of adding a cron job that nightly restarted MySQL and Apache, as those were my memory-gobbling culprits, the latter frequently guilty of heavy swapping. With cron job in place, though, life was good again, and I never thought much more about it.

Until completely by accident I discovered Nginx.

Even though it was very recent, I don't remember how I found out about Nginx. But, somehow, I did. Within a week I had installed it on my server and was running my beta WordPress install -- where I try out new themes, test new layouts, and develop my own WordPress plugins -- on Nginx, using PHP-FPM as the FastCGI wrapper around PHP.

But why use a wrapper? So within a week of getting that up and running, I tore out PHP-FPM and am now simply using PHP's own built-in FastCGI process manager. The result? A noticeably speedier server that uses much less RAM and CPU. Sure, I could probably tweak Apache to accomplish the same thing, but Nginx is a lot simpler to configure and tweak, and runs with a very low footprint right out of the box -- no tweaking required!

The rest of this post will describe how you, too, can migrate from your LAMP stack to a LEMP one, and specifically go over how to use it to run WordPress. As such, I will not cover installing Linux, MySQL, or even PHP, as I am assuming you already have (or know how to set up) a LAMP stack, and skip right ahead to installing Nginx, configuring it, and using it to proxy a PHP FastCGI server. My system is Ubuntu 9.04, but since I installed Nginx from source and am assuming you've already installed (or know how to install) the other elements you should be able to follow along without any problems.

The first thing to do, of course, is to download and extract the latest version of the Nginx source; although they say that the development version is stable enough for use, I chose to use the latest stable version. At the time of this writing, that's 0.8.54. You can find the latest version [here](http://wiki.nginx.org/Install).

    
    
    $ cd /tmp
    $ mkdir nginx
    $ cd nginx
    $ wget http://sysoev.ru/nginx/nginx-0.8.54.tar.gz
    $ tar -xvvzf nginx-0.8.54.tar.gz
    $ cd nginx-0.8.54
    



Wait a second, you say. I said I was running Ubuntu, so why don't I just `apt-get install nginx`? Well, I did want to take advantage of the wide range of compile-time options to configure the server to run just as I need it, to help control the resource footprint. But primarily, the version in the Ubuntu repositories is way out of date -- 0.6.35 at the time of this writing, which is even older than the "legacy" version (0.7.68) offered for download from the Nginx website! In addition to just being way too old, it lacks support for the 'try_files' directive, which we'll use later to get WordPress running.

Before you compile, you need to ensure you satisfy the dependencies. The configure command will tell you if you're missing anything; in my case, I was only missing the PCRE libraries, which were easily installed via aptitude.

    
    
    $ sudo apt-get install libpcre3-dev
    



Nginx has a plethora of compile-time options. Check out [the list](http://wiki.nginx.org/NginxInstallOptions), and make sure you use the ones you need/want. In my case, my configure command looked something like this:

    
    
    $ ./configure \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/logs/nginx/error.log \
      --http-log-path=/var/logs/nginx/access.log \
      --with-http_ssl_module
    



Then it's time to compile and install:

    
    
    $ make
    $ sudo make install
    



Now we get to configure our installation. As you can see from my configure options above, I've put my configuration into `/etc/nginx/`, for the sole reason that I'm used to configurations being in etc or a subdirectory thereof. I'm also used to Apache's (Debian's/Ubuntu's?) standard of configuring virtual hosts in separate files in a sites-available subdirectory, then symlinking to them from a sites-enabled directory and simply including everything in that directory from the main config file. So, that's what I chose to do:

    
    
    $ sudo mkdir /etc/nginx/sites-available /etc/nginx/sites-enabled
    



Now let's configure Nginx. Here's `/etc/nginx/nginx.conf`:

    
    
    user  www-data;
    worker_processes  2;
    
    pid        /var/run/nginx.pid;
    
    events {
    	worker_connections  1024;
    }
    
    http {
    	include       mime.types;
    	default_type  application/octet-stream;
    
    	sendfile        on;
    
    	keepalive_timeout  65;
    	index index.html index.htm index.php;
    
    	gzip  on;
    
    	# Upstream to abstract backend connection(s) for php
    	upstream php {
    		server unix:/tmp/php5.socket;
    	}
    
    	include sites-enabled/*;
    }
    



Since this isn't an in-depth tutorial on the workings and goings-on of Nginx, I'm not going to go into too much detail about what everything here means. I do want to point out a couple of things, though.

First is this section:

    
    
    # Upstream to abstract backend connection(s) for php
    upstream php {
    	server unix:/tmp/php5.socket;
    }
    



This block is where we are defining how we are talking to PHP from Nginx (more on the specifics later, when we configure PHP for FastCGI). It does nothing more than reduce code duplication, as we can now tell Nginx to simply proxy PHP files to "php" -- we'll see that, too, in a moment.

The other part I want to point is line 26: `include sites-enabled/*;`. This is the magic that makes our Apache-esque sites-available and sites-enabled directories work: It is quite simply telling Nginx to go into our sites-enabled directory and read every file it finds in there. Magic!

Now let's start setting up virtual hosts. I'll start by very simply solving what I've always found to be endlessly frustrating in Apache: Not responding at all to requests directed at our server for a host we're not hosting:

    
    
    ##
    # Default server
    # Simply ignore any request with a hostname we don't recognize
    ##
    
    server {
    	# This is our default server
    	listen 80 default_server;
    
    	# Not attached to any particular hostname
    	server_name _;
    
    	# Don't respond to any host we haven't configured
    	return 444;
    }
    



This is really nothing more than a near-verbatim copy of the example that can be found [here](http://nginx.org/en/docs/http/request_processing.html#how_to_prevent_undefined_server_names), so I won't go into what it's doing beyond to say that this tells Nginx to simply close the connection without sending a response if the client tries talking to a virtual host that doesn't exist on our server.

Now let's set up this server:

    
    
    server {
    	listen 80;
    	server_name kromey.us;
    	root /var/www/kromey.us/htdocs;
    	include default_locations;
    
    	location / {
    		# This is cool because no php is touched for static content
    		try_files $uri $uri/ /index.php;
    	}
    
    	location ~ \.php$ {
    		#NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
    		include fastcgi_params;
    		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    		fastcgi_pass php;
    	}
    }
    



This file sets up the virtual host for kromey.us, which you're reading this post on. It's listening on port 80, and responds to requests with a Host header of "kromey.us". We set up the document root, then we include another file (which I'll come back to), and then we define some location blocks.

The first one (`location /`) is the magic that makes WordPress's pretty permalinks work. Its single line does three things:



	
  1. Check for the requested file, and serve it if found.

	
  2. Check for the requested directory index, and serve that if found.

	
  3. Serve /index.php is neither of the first 2 were found.



This allows paths such as "/wp-content/uploads/2011/02/binary_header.jpg" (my current theme's header image) to be served directly, without involving PHP at all, but to send requests for "/2011/02/wordpress-on-a-lemp-stack-366.html" (this post) to WordPress's front controller-pattern index.php, allowing it to parse the permalink and serve up the content you are reading now.

Isn't that so much neater and cleaner than the mod_rewrite rules needed to serve up WordPress on Apache?

    
    
    # WordPress rewrite rules
    <IfModule mod_rewrite.c>
    	<Location />
    		RewriteEngine On
    		RewriteBase /
    		RewriteCond %{REQUEST_FILENAME} !-f
    		RewriteCond %{REQUEST_FILENAME} !-d
    		RewriteRule . /index.php [L]
    	</Location>
    </IfModule>
    



The second location block sends all of our PHP files to PHP. Note that we're specifying that we're passing the request to "php", as opposed to specifying the socket directly here -- this is that upstream block from our main config file. Makes this bit a lot easier, doesn't it?

I won't go into further depth on this block, mainly because it's pretty standard -- find any "PHP on Nginx" tutorial and you'll see basically the same thing, although most likely without the use of the abstracted upstream block.

One final piece now to our Nginx config, and then we're done here: the default_locations file you saw included above:

    
    
    # Be quiet about the favicon
    location = /favicon.ico {
    	log_not_found off;
    	access_log off;
    }
    
    # Be quiet about robots.txt
    location = /robots.txt {
    	allow all;
    	log_not_found off;
    	access_log off;
    }
    
    # Static content
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    	expires max;
    	log_not_found off;
    }
    



This file does 3 simple things:



	
  1. Don't log requests for the site's favicon, and don't log 404 "file not found" errors for it.

	
  2. Don't log requests for the site's robots.txt file, don't log 404 errors for it, and make sure anyone and everyone can access it (not really relevant to our setup, but if you were to, say, add config that block bots/crawlers from your site, this would ensure that they can still access your robots.txt file, which in such a case should tell them to just go away).

	
  3. Serve our static content with a long expiration date in the Expires header. Very long one.



Since I want these configs to be in pretty much all of my sites, I've put them in this separate file (which, by the way, needs to be located at `/etc/nginx/default_locations` for the include as-written to work) so they can be easily repeated everywhere. Since I also host multiple virtual hosts running PHP, as well as multiple hosts running WordPress instances, I should probably also put the PHP and WordPress location blocks into separate files and include them as well, but I haven't done that yet.

So, now with both of these virtual hosts in `/etc/nginx/sites-available/`, all we have to do is create symlinks to them in `/etc/nginx/sites-enabled/`, and Nginx will then find them and use them. Once you've done that, start up Nginx and you're ready to rock!

...You just did that and got an error, didn't you? I got a little ahead of myself -- we haven't configured PHP to run as a FastCGI server listening for our connections yet. Fortunately, this is easy enough:

    
    
    $ php-cgi -b /tmp/php5.socket &
    



_Now_ you can serve up PHP scripts and even WordPress instances through Nginx. Although your PHP FastCGI server isn't going to be quite all there just yet. For starters, if you've done any changes to the php.ini file used by Apache, then you should make sure that php-cgi is using the same php.ini file, or else copy your changes over. The latter is the simplest option, and is easy enough on Debian/Ubuntu:

    
    
    $ sudo cp /etc/php5/apache2/php.ini /etc/php5/cgi/php.ini
    



Finally, we'll want to create a shell script to start PHP FastCGI for us so that we can establish a few parameters, since as how many child processes it should spawn, and how long each should last:

    
    
    #!/bin/sh
    
    # Set up some parameters
    WWW_USER=www-data
    PHP_CGI=/usr/bin/php-cgi
    
    phpfcgid_socket="/tmp/php5.socket"
    phpfcgid_children="5"
    phpfcgid_requests="100"
    
    # Make them available to PHP
    export PHP_FCGI_CHILDREN=$phpfcgid_children
    export PHP_FCGI_MAX_REQUESTS=$phpfcgid_requests
    
    # Start the PHP FastCGI server
    su -m ${WWW_USER} -c "${PHP_CGI} -b ${phpfcgid_socket} &"
    



Notice that we're now properly running our PHP FastCGI server under a limited user account; this also means that you'll probably have to be root -- or, better yet, use sudo -- to run this script. This code can also be used in an init script. Really, you probably do want to put Nginx and PHP FastCGI into init scripts, at the very least so that they come up on their own after a server reboot. This post is already quite long, though, and I'm really not familiar with the intricacies of init scripts, so I won't go into them here. I may cover them in a later post, though.
