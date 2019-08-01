---
author: admin
comments: true
date: 2016-01-24 22:07:08+00:00
layout: post
link: https://kromey.us/2016/01/raspberry-pi-as-a-gateway-721.html
slug: raspberry-pi-as-a-gateway
title: Using a Raspberry Pi as a Network Gateway
wordpress_id: 721
categories:
- How-to
tags:
- dhcp
- dns
- firewall
- guide
- linux
- networking
- raspberry pi
---

The Raspberry Pi is an amazing little piece of hardware, an entire computer in a form factor not much larger than your wallet. While not boasting specs to make it the envy of your household, it is nonetheless quite the capable little device, and with just a couple of simple accessories you can even use it to run your entire home network!

I've done precisely that, and in this lengthy, record-setting post, I'm going to share precisely how I turned a Raspberry Pi B+, with nothing more than a power supply and USB-to-Ethernet adapter, into the "Command & Control" center of my entire home network.

I acquired my Pi long before I started on this project, which was completed long before I finally got around to this write-up; suffice it to say that the model 2 wasn't available yet, but even so the B+ is still plenty capable.

On my network, my Pi currently routes all network traffic between the private network and the internet, while also providing DHCP and DNS services. It's managed via SSH. I have plans to add a web-based management interface in the future, and to expand its capabilities to at least include ad-blocking (similar to [Pi-Hole](http://pi-hole.net/)) and wi-fi, but who knows what else is in its future -- so far I'm not even scratching the surface of its capabilities!

For this project I used the standard Raspbian image, on a little 8GB card. I won't be going into how to get started setting up your Pi, so from here on out we're assuming you already have it up and running. After updating everything, the first thing I did was to remove most of the GUI-related cruft, since this was going to be a purely headless system:


    
    
    $ sudo apt-get remove -y --purge libx11-.*
    $ sudo apt-get --purge autoremove
    



This dropped the size of my install from 2.5GB to a very slim 1.0GB. It's not strictly necessary of course, and there's plenty of space either way, but it's good practice to keep anything that isn't necessary off of your security devices. There are limits to how far I'm willing to go for that, however, so I didn't dig deeper into what else I could remove; you could probably slim it down even further.



## Configuring the Interfaces



Next, I plugged in this [USB 10/100 Ethernet adapter](http://www.amazon.com/gp/product/B00484IEJS/ref=as_li_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=B00484IEJS&linkCode=as2&tag=sd41net-20&linkId=AGCCCSPM26X3RTSZ); there's no doubt others that would work fine, but this is the one I used, and it Just Works® with no drivers necessary. This is going to be the external/WAN interface, the one facing the internet. _Do not_ connect this one to any network yet, though.

Now you need to assign a static IP address on the internal interface. At the same time, learning from my past mistakes, I renamed it to `lan0`; I likewise took the opportunity to rename the external interface to `wan0`. (In past projects, I could never remember if `eth0` or `eth1` was my internal interface, and which was my external interface.)

Edit or create the file `/etc/udev/rules.d/70-persistent-net.rules`, and fill it in with the following:


    
    
    # Manually added to rename eth0 to lan0
    # Line breaks added for readability, this should all be one line
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*",\
     ATTR{address}=="YOUR MAC", ATTR{dev_id}=="0x0",\
     ATTR{type}=="1", KERNEL=="eth*", NAME="lan0"
    
    # Rename the external interface as well
    # Line breaks added for readability, this should all be one line
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*",\
     ATTR{address}=="YOUR MAC", ATTR{dev_id}=="0x0",\
     ATTR{type}=="1", KERNEL=="eth*", NAME="wan0"
    



Make sure you replace the MAC addresses above ("`YOUR MAC`") with the ones for your Pi's interfaces, which you can find from the output of `ifconfig` (add the `-a` option to show interfaces that aren't currently up, such as your external one). Then edit the file `/etc/network/interfaces` and configure your `lan0` interface with a static IP (removing anything that references your `eth0` interface), and add lines for `wan0` (probably DHCP, but this will be determined by your ISP):


    
    
    auto lan0
    iface lan0 inet static
        address 10.0.0.1
        netmask 255.0.0.0
    
    auto wan0
    iface wan0 inet dhcp
    



You can of course use a different IP and/or different network, I just like this one. :smile:

Reboot your Pi to make these changes take effect; once you confirm everything is running as expected, you can do the rest of the configuration over SSH, using the IP you configured on `lan0`.



## Setting up DNS



To keep things simple, we're going to use [`dnsmasq`](http://www.thekelleys.org.uk/dnsmasq/doc.html) for both DNS and DHCP, but we're going to set up each component separately. DNS is the simpler to configure, so we'll start there.

First, install `dnsmasq`:


    
    
    $ sudo apt-get install dnsmasq
    



The main configuration file is in `/etc/dnsmasq.conf`, but Raspbian will also look for files in the `/etc/dnsmasq.d/` directory; this means we can break our configuration out into manageable pieces in this directory, rather than trying to manage everything from that one ginormous file.

To do so, I recommend finding the related sections of the main file, and copy/pasting them into the smaller files we're about to discuss. However, for brevity, all I'm going to show here is the options and values we need to set.

To get DNS working, we need very little; create the file `/etc/dnsmasq.d/dns.conf`, and put these settings in it:


    
    
    # Never forward plain names (without a dot or domain part)
    domain-needed
    # Never forward addresses in the non-routed address spaces.
    bogus-priv
    # Ignore /etc/resolv.conf, using our own settings instead
    no-resolv
    # We also don't need to poll that file
    no-poll
    # Now set our DNS forwarders
    server=8.8.8.8
    server=8.8.4.4
    



The first option, `domain-needed`, means that our users can use short local names without accidentally broadcasting them to the world. `bogus-priv` tells `dnsmasq` that any response from our forwarders for a local address should be ignored; this is probably unnecessary, but can prevent some attacks and isn't likely to ever be a legitimate response anyway.

The next two options disable `dnsmasq`'s tendency to use `/etc/resolv.conf` to find DNS servers; if we don't disable this, we can't set our servers in this file, which is the only option to set our own servers if our ISP uses DHCP, as the DHCP client will overwrite this file each time.

The two `server` options, then, tell our server where to look for forwarded responses. In this example I'm using Google's [Public DNS](https://developers.google.com/speed/public-dns/?hl=en) servers, but you could just as easily substitute, say, [OpenDNS](https://www.opendns.com/home-internet-security/) instead (208.67.222.222 and 208.67.220.220), which then gives you access to their filtering options. _[Note: We'll look at DNS-based filtering and security, including OpenDNS, in a future post.]_

After a quick restart of the service, you can test by using e.g. `dig`:


    
    
    $ sudo service dnsmasq restart
    $ dig @10.0.0.1 google.com
    



(Make sure you use _your_ Pi's IP address here!) If everything is working right, you should get a response listing a dozen-ish IP addresses for google.com. (In a future post I'll show you how to set up DNS resolution for your own internal names.)



## Setting up DHCP



Now that we have DNS working, let's get our Pi set up to automatically hand out IP addresses to any device that connects to our network. This is still pretty simple at this point, since we're not going to be dealing with static DHCP leases yet. [We'll add that in a future post.]

First, to start with the basics, create the file `/etc/dnsmasq.d/dhcp.conf` with the following:


    
    
    # Specify our DHCP range
    dhcp-range=10.0.0.50,10.0.0.150,12h
    



For our purposes today, this is all we need. There's nothing special about this range; pick one you like, and make sure there's enough IP addresses in the range to cover everything that might connect. This option specifies that any address in the range 10.0.0.50 through 10.0.0.150 can be handed out to a device requesting an address, and that each lease is valid for 12 hours. I like to leave myself a comfortable margin in the beginning of my chosen range for static assignments, but there's no need to then fill up the rest of the address space with DHCP -- 100 addresses is more than enough for my needs. However, we did specify that we have the entire 10.0.0.0 through 10.255.255.255 network at our disposal earlier when we configured the IP address, so you really can pick whatever you want in that _huge_ range to be set aside for your DHCP leases; we may explore some of the options this gives us in a future post.

Don't jump off and restart your Pi just yet, though. There's a problem with this setup, namely that once we plug the Pi into our ISP's network, it may begin handing out DHCP leases to your ISP's other customers! To prevent this, create the file `/etc/dnsmasq.d/interfaces.conf`, and add this:


    
    
    # Interfaces to listen for DHCP and DNS services
    interface=lan0
    # Bind only to the interface(s) we're listening one
    bind-interfaces
    



This tells `dnsmasq` to ignore any DHCP or DNS requests that come in on any interface other than our internal `lan0` interface; further, we're not even going to listen except on this interface. We could further secure this with firewall rules; while we will be delving briefly into the firewall in a moment, we won't discuss this option until a later post.

One more thing we're going to do: We're going to assign a domain to our local network. Ideally, you should use a domain you control and set aside a subdomain you'll use for no other purpose (e.g. if you owned contoso.com, you could set aside home.contoso.com for your home network's domain), but you can use one of the ["Special-Use Domain Names"](http://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml) (or a subdomain thereof) instead if you would prefer.

Create the file `/etc/dnsmasq.d/domain.conf`, and add the following:


    
    
    # Set this to automatically add a domain to host names
    expand-hosts
    # Set the domain for dnsmasq
    domain=home.example.com
    



When we start adding local names to our configuration (in a later post), we can specify the "local" part only (e.g. `mylaptop`), and `dnsmasq` would automatically expand that to `mylaptop.home.example.com`. It's always a good idea to "scope" your local names like this, otherwise as new gTLDs come online you might find that you're effectively blocking your entire network from accessing them if they just happen to match a locally defined name.

Before you restart `dnsmasq` again, you should turn off any other DHCP service you have running on your network. Actually, at this point, you really just have to install the Pi as your perimeter gateway, since this DHCP configuration will make it the "gateway" for any device it gives a lease to, but before we do that we have one more crucial step: We have to enable our Pi to forward local traffic to the internet.



## Forwarding Network Traffic



The first step is to enable packet forwarding in our kernel. We do this in `/etc/sysctl.conf` by uncommenting this line:


    
    
    # Uncomment the next line to enable packet forwarding for IPv4
    net.ipv4.ip_forward=1
    



This won't take effect until the next reboot; to make it take effect immediately, you can do this (as root):


    
    
    $ echo 1 > /proc/sys/net/ipv4/ip_forward
    



That alone is not enough, however. We now need to tell `iptables` what we're forwarding to where, which is accomplished with this command:


    
    
    $ sudo iptables -t nat -A POSTROUTING -o wan0 -j MASQUERADE
    



This rule tells our Pi that traffic reaching it on another interface, but destined for elsewhere, should be translated into traffic that appears to come from its own `wan0` interface, and then sent from that interface. If this sounds like NAT to you, that's because it is -- specifically, SNAT.

Unfortunately, if you were to reboot right now, this rule would be gone; we have to make our `iptables` rules persistent if we want this to really be a viable long-term solution. Fortunately that's accomplished easily with the `iptables-persistent` package:


    
    
    $ sudo apt-get install iptables-persistent
    



When you install it, it will ask if you want to save the current rules; choose "Yes" to have your current rules written to the file `/etc/iptables/rules.v4`; unless you've taken the time already to enable IPv6 on your Pi, say "No" when it asks if you want to save your IPv6 rules. (IPv6 may be discussed in a later post, but not before my own ISP enables it.)

While you can edit this file directly, in general it's better to add new rules directly to your active firewall using `iptables`, and then saving them to that file using either `dpkg-reconfigure iptables-persistent` or `iptables-save > /etc/iptables/rules.v4`.

At this point you can connect your external interface to the hookup from your ISP, and the internal one to your network, and your Pi will serve as your network's edge gateway, DHCP server, and DNS server. The firewall is _very_ permissive at this point; we'll lock it down in the next post.
