---
author: admin
comments: true
date: 2010-03-23 02:45:59+00:00
layout: post
link: https://kromey.us/2010/03/defend-your-ssh-server-316.html
redirect_from: /2010/03/defend-your-ssh-server-316.html
slug: defend-your-ssh-server
title: Defend Your SSH Server
wordpress_id: 316
categories:
- Security
tags:
- firewall
- Security
- ssh
---

If you manage one or more servers, chances are you employ SSH for remote management of that server. If you've checked the logs for your SSH server (you _do_ check your logs, don't you?), chances are you've seen plenty of these:

    Mar 21 12:25:15 odin sshd[28010]: Did not receive identification string from 61.184.104.106
    Mar 21 12:29:32 odin sshd[28011]: Invalid user webmaster from 61.184.104.106
    Mar 21 12:29:33 odin sshd[28011]: pam_unix(sshd:auth): check pass; user unknown
    Mar 21 12:29:33 odin sshd[28011]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=61.184.104.106
    Mar 21 12:29:35 odin sshd[28011]: Failed password for invalid user webmaster from 61.184.104.106 port 53329 ssh2
    Mar 21 12:29:41 odin sshd[28013]: User root from 61.184.104.106 not allowed because none of user's groups are listed in AllowGroups
    Mar 21 12:29:41 odin sshd[28013]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=61.184.104.106  user=root
    Mar 21 12:29:43 odin sshd[28013]: Failed password for invalid user root from 61.184.104.106 port 56109 ssh2
    Mar 21 12:29:45 odin sshd[28015]: Invalid user ftp from 61.184.104.106
    Mar 21 12:29:45 odin sshd[28015]: pam_unix(sshd:auth): check pass; user unknown
    Mar 21 12:29:45 odin sshd[28015]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=61.184.104.106
    Mar 21 12:29:47 odin sshd[28015]: Failed password for invalid user ftp from 61.184.104.106 port 59859 ssh2

There's countless ill-intentioned folks out there who would love to gain access to your system. SSH is a great doorway, all they need to do is find the key; hopefully they haven't (but if they had, would you know?), and today I'm going to show you 4 ways to keep your server safe. I won't harangue you on strong passwords or using public keys instead of passwords; instead, I'll show you other measures you can take to improve the security of those mechanisms.

**1) Delete the root user's password**

(Unix- and Unix-like-specific.) No one should directly log in to the root account; instead, each person who has a need for root-level access should have their own user account with `sudo` privileges. For times when you're going to be doing a lot of root-level tasks, though, typing "sudo" at the front of every command can get tedious, which is why many server administrators break this rule; however, for those cases, a simple `sudo su -` is acceptable and still keeps your root user passwordless.

If you've already assigned a password for root (which many distributions force you to do during installation), you can delete the root user's password like so:


    
    sudo passwd -d root



_Make sure you've given yourself sudo access first!_ If you do this as the root user and you log out before granting your own user sudo access, you will lock yourself out of all root-level tasks on your server.

**2) Restrict the users that can use SSH**

The more users on your servers, the larger the attack surface for someone who wants to gain access to your server. While it's a best practice to create separate user accounts for different processes, do you really need your apache user to have SSH access?

Fortunately, this is simple. Create a separate user group to which you'll assign users who need SSH access; I like "sshusers" myself. Then edit your `/etc/ssh/sshd_config` so that the following configuration parameters have the values shown:


    
    PermitRootLogin no
    AllowGroups sshusers



This does two things: The first line, of course, out-and-out prohibits the root user from being allowed to log in to your SSH server. The second line simply restricts the permissible logins to be those within the sshusers group. Grant group ownership to the appropriate user accounts, and you're good to go!

This also aids in auditing -- someone who does gain access to your server, whether by SSH or other means, would probably want to ensure that they have a back door for future use. A simple way of doing that is to simply grant a shell and assign a password to any one of the myriad of system accounts on your server. This can be very hard to spot. However, if you restrict SSH access to one particular group, your security audit (in respect to who can SSH into your server, that is) is much simpler: Verify that nobody's changed the AllowGroups or PermitRootLogin directives, and verify that only the users that should be in the sshusers group are.

**3) Reduce brute force attempts at the firewall**

Until I adopted all the practices described in this post, I had several obvious brute force attempts showing up in my logs -- hundreds if not thousands of attempts to log in to a single user account, repeated for dozens upon dozens of user accounts. With some creative application of firewall rules, however, those hardly ever show up anymore.

Using [Shorewall](http://www.shorewall.net/), I configured a simple LIMIT rule for my SSH server:


    
    Limit:info:SSHA,3,180   net     all             tcp     22



This limits any given host from making more than 3 SSH connections in any given 3-minute interval of time; given that most SSH servers seem to permit 3 login attempts on a single connection, this means that in any given 3-minute interval, no more than 9 password attempts can be made. Since most brute forcers will hit this limit within seconds, they're subsequently blocked at the firewall for the next 3 minutes - most will give up immediately.

A stronger alternative is to employ ["port knocking"](http://www.shorewall.net/4.2/PortKnocking.html) to make your SSH server completely invisible except to those who know the "secret knock". The downside to this, however, is that no SSH client I'm aware of supports this, so you'd be reliant upon an external tool to permit your SSH client to connect.

**4) Employ measures to ban brute force attackers**

I use a Perl script called [DenyHosts](http://denyhosts.sourceforge.net/index.html) to do this. In a nutshell, this script monitors the failed login attempts (as reflected in the logs) to your SSH server and, when certain conditions are met, bans the offending host from even connecting to your server.

Some tips on configuring this script:



	
  1. Ban attempts to log into the root user after a single try -- if you're following the advice in this blog, the root user can't be logged into anyway, so no one who should be logging into your server will be using that account.

	
  2. Don't set the invalid user threshold too low -- if you simply mistype your user name, you could easily hit 3 failed login attempts without even knowing it!

	
  3. Consider a "three strikes" policy -- if a host gets banned, allow your system to purge that ban at most twice; after their third strike, however, they're outta there!

	
  4. Don't be too harsh -- users, even valid users, are, in the end, only human, and they can make mistakes. Don't set your thresholds too low that you get too many false positives.

	
  5. Don't be too lenient -- good attackers know what they're doing, and if your users happen to have weak passwords a few guesses can gain unauthorized access. Better to lean toward too harsh -- you can always [restore access to an erroneously-banned host](http://denyhosts.sourceforge.net/faq.html#3_19).

	
  6. If you use Shorewall for your firewall, you can use the command `/sbin/shorewall drop` for PLUGIN_DENY and `/sbin/shorewall allow` for PLUGIN_PURGE to shift the burden of watching for banned users out to your firewall instead of your services.





There's certainly more that you can do to protect your server from unauthorized access. A strong password policy plus these 4 tips are simply what I use. Post your own tips and advice in the comments.
