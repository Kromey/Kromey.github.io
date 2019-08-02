---
author: kromey
comments: true
date: 2011-04-30 22:47:31+00:00
layout: post
link: https://kromey.us/2011/04/microsofts-virtual-machine-manager-host-not-responding-398.html
redirect_from: /2011/04/microsofts-virtual-machine-manager-host-not-responding-398.html
slug: microsofts-virtual-machine-manager-host-not-responding
title: 'Microsoft''s Virtual Machine Manager: "Host not responding"'
wordpress_id: 398
categories:
- Tech
tags:
- gpo
- guide
- virtualization
- windows
---

Microsoft's Virtual Machine Manager, or VMM, is a slick piece of tech that smoothly enables users to control virtual machines spread out across multiple hosts, including, of course, localhost.

But what happens when VMM reports "Host not responding", even for localhost?

This was the question I faced not too long ago. The usual troubleshooting measures I found online (make sure the firewall's letting you through, make sure the proper services are installed and running, etc.) turned up nothing improper or unusual.

Until, purely out of lack of anything better to do, I typed the command `winrm enum winrm/config/listener`, and I got this:


    
    
    Listener [Source="GPO"]
        Address = *
        Transport = HTTP
        Port = 80
        Hostname
        Enabled = true
        URLPrefix = wsman
        CertificateThumbprint
        ListeningOn = null
    



Wait a second! `ListeningOn = null`?? That doesn't look right. To be sure, I ran the same command on a server where VMM was working just fine:


    
    
    Listener [Source="Compatibility"]
        Address = *
        Transport = HTTP
        Port = 80
        Hostname
        Enabled = true
        URLPrefix = wsman
        CertificateThumbprint
        ListeningOn = 10.0.0.88, 127.0.0.1, 192.168.2.119, [snip]
    



Well, that looks more like what it should -- listening on every IP on the machine. So why was the first one not listening? The "Source" listed on the first line is the clue: Group Policy is configuring the WinRM that isn't working, but not the one that is. So the obvious conclusion is that the GPO is misconfigured.

So let's run `gpresult /v /scope computer` and see what's going on (snipped for clarity and brevity):


    
    
                GPO: Default Domain Policy
                    KeyName:     Software\Policies\Microsoft\Windows\WinRM\Service\AllowAutoConfig
                    Value:       1, 0, 0, 0
                    State:       Enabled
    
                GPO: Default Domain Policy
                    KeyName:     Software\Policies\Microsoft\Windows\WinRM\Service\IPv4Filter
                    Value:       0, 0
                    State:       Enabled
    
                GPO: Default Domain Policy
                    KeyName:     Software\Policies\Microsoft\Windows\WinRM\Service\IPv6Filter
                    Value:       0, 0
                    State:       Enabled
    



So we're allowing WinRM to be configured, and then filtering it to... what? Nothing at all? Reading the actual values of policies from this command is not the easiest thing to do, but I'll just cheat and hand you the answer: "Value: 0,0" means, basically, that it's filtered to not listen on any IP. Well, more accurately, on IP 0.

Doing some research, it turns out you can configure WinRM to listen on all IPs by simply specifying '*' in the IPv4 and IPv6 filters. Doing this (and then forcing the update with `gpupdate /force`) results in this change in the GPO:


    
    
                GPO: Default Domain Policy
                    KeyName:     Software\Policies\Microsoft\Windows\WinRM\Service\AllowAutoConfig
                    Value:       1, 0, 0, 0
                    State:       Enabled
    
                GPO: Default Domain Policy
                    KeyName:     Software\Policies\Microsoft\Windows\WinRM\Service\IPv4Filter
                    Value:       42, 0, 0, 0
                    State:       Enabled
    
                GPO: Default Domain Policy
                    KeyName:     Software\Policies\Microsoft\Windows\WinRM\Service\IPv6Filter
                    Value:       42, 0, 0, 0
                    State:       Enabled
    



Hm, "Value: 42, 0, 0, 0"? That's odd, isn't it? Well, no one's ever accused Microsoft of doing things in a logical, sane way! Regardless of the odd, cryptic output here, this fixed our problem, and WinRM was again listening on all IPs. This allowed VMM to once again connect to these hosts and once again control the VMs installed on them.

Now why couldn't someone have told me this from the get-go???
