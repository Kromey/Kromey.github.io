---
author: kromey
comments: true
date: 2009-12-11 04:31:33+00:00
layout: post
link: https://kromey.us/2009/12/networking-201-running-your-own-dhcp-server-229.html
redirect_from: /2009/12/networking-201-running-your-own-dhcp-server-229.html
slug: networking-201-running-your-own-dhcp-server
title: 'Networking 201: Running your own DHCP server'
wordpress_id: 229
categories:
- How-to
- Tech
tags:
- dhcp
- guide
- networking
- ubuntu
---

Whether you run a small business network, or just your own home network, you've probably made use of what I call "plastic routers" - off-the-shelf devices that you plug in to share your single internet hookup between multiple computers. These convenient little boxes provide routing, basic firewalling, DHCP, and occasionally even DNS support for your network, via a handy web interface. However, if you find these devices to be too limiting, or you just want to flex your geek muscle by doing it all yourself, one of the first things you'll need is a DHCP server.

This post will walk you through installing and configuring `dhcp3-server` on an Ubuntu server. The nice thing about this is that the resource requirements are very low - I use an old HP Pavilion computer running a scant 64 MB of RAM with a sloth-like 667 MHz processor, which is more than enough to also serve as my network's DNS server and firewall. Installing Ubuntu in such a slim environment can be vexatious, but it runs just fine once installed; that, however, is beyond the scope of this post - for now I will simply assume you have Ubuntu installed and ready to go.

This is the first in a short series of articles about networking set up and configuration; this post will serve as reference material for later how-tos, including a detailed description of how I make effective use of [VirtualBox](http://www.virtualbox.org/)'s internal network feature to virtualize entire networks of VMs.

Before we start installing and configuring software, we need to make a couple of decisions about what our network should look like. The first decision is what range of non-routable IP addresses to use; you can choose from 10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16. You can also choose to increase the size of the bitmask if you want; I usually set up my networks on 10.0.0.0/8 or /24, however for this article I arbitrarily chose 172.24.0.0/24. There is no practical difference between the 3 available networks, beyond the number of IP addresses available within them. Pick whatever one you like.

A quick note about the networks listed in the previous paragraph: I used CIDR notation, a quick way to express the entire range of IP addresses in a network. If you're unfamiliar with CIDR notation, head on over to the [Wikipedia page](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). Also, since /12 doesn't neatly fit onto the octet divisions in an IP address, I'll mention that 172.16.0.0/12 covers the range 172.16.0.0 – 172.31.255.255.

Your next decision is where to put your DHCP server; since mine will also serve as my network's gateway, and I like my gateways to be at the lowest IP address of a network, I chose 172.24.0.1 for mine. The only requirements for you, however, are that you must choose an IP that is within your chosen network, and you must choose one that is outside the range of your DHCP leases (that's our next step).

Finally, you have to choose which IP addresses to use for your DHCP range. I recommend leaving space in your network both above and below your range to allow for fixed addresses on your network (which should never be exposed to the risk of conflicting with a DHCP lease); if you're using a /24 network like I am, .100 through .200 is a fine choice. I'm using 172.24.0.100 through 172.24.0.200.

Okay, now we begin to configure our server. I'm assuming you've already installed Ubuntu, so the first thing we need to do is to statically assign ourselves and IP address; we cannot use a DHCP lease for this one, as it is your classic "chicken-or-egg" problem, except with a definitive answer: The DHCP server must have an IP address before it can assign any IP addresses.

Fortunately, this isn't painful in Ubuntu. Open up the file `/etc/network/interfaces`; modify the lines for eth0 (assuming eth0 is your network interface) so they look like this:


    
    auto eth0
    iface eth0 inet static
        address 172.24.0.1
        netmask 255.255.255.0



If you don't have lines for eth0, that's fine - just add these. Be sure to replace the address and netmask values with the appropriate ones for the network you chose earlier. Now verify that your new configuration is working:


    
    kromey@gateway:~$ sudo /etc/init.d/networking restart
     * Reconfiguring network interfaces...
     ...snip networking services restarting...
                                                              [ OK ]
    kromey@gateway:~$ ifconfig
    eth0      Link encap:Ethernet  HWaddr 00:1f:c6:30:9a:3b
              inet addr:172.24.0.1  Bcast:172.24.0.255  Mask:255.255.255.0
              ...snip a bunch of extra information...



If you get no errors from the restart, and `ifconfig` shows eth0 on your chosen IP address, you've done everything right! Otherwise, go back and verify that you typed everything correctly in `/etc/network/interfaces`.

Now that our server is up and running and has an IP address on our network, it's time to install the DHCP server.


    
    kromey@gateway:~$ sudo apt-get intall dhcp3-server



Once that's installed, we'll need to configure it to start serving DHCP leases for the network; remember, I chose 172.24.0.0/24, with my DHCP leases occupying 172.24.0.100 - 172.24.0.200. Edit `/etc/dhcp3/dhcpd.conf` and configure your chosen network:


    
    subnet 172.24.0.0 netmask 255.255.255.0 {
        range 172.24.0.100 172.24.0.200;
        option routers 172.24.0.1;
    }



You'll notice that I configured the routers option to point right back to my DHCP server; this is because, as I mentioned earlier, my plan involves using this same server as my network's gateway. If you just want to get up and running now, and you have a "plastic router" to use for the gateway, put that device's IP address into the routers option. Do note, however, that its IP address must be inside your subnet.

Next, we need to verify some basic settings, and make any changes as necessary. We need to make sure that the computers in our network can perform DNS lookups correctly. Since we have not yet configured a DNS server for ourselves, this example uses [OpenDNS](http://www.opendns.com/)'s servers. Find the line that references `domain-name-servers` near the beginning of the file, and change it to this:


    
    option domain-name-servers 208.67.222.222, 208.67.220.220;



You could alternatively use [Google](http://code.google.com/speed/public-dns/docs/using.html)'s (8.8.8.8, 8.8.4.4) or your own ISP's DNS servers here; a later post will show you how to set up your own DNS server, for which we'll update this setting.

The final thing we need to do here is to tell our DHCP server that it is authoritative for our network; this consists of simply uncommenting (deleting the leading '#' character) the line `authoritative;` in our configuration file.

Now start up `dhcp3-server` and, if there are no errors in your configuration, make sure it's added to your runlevels so that it starts up appropriately.


    
    kromey@gateway:~$ sudo /etc/init.d/dhcp3-server start
     * Starting DHCP server dhcpd3                                            [ OK ]
    kromey@gateway:~$ sudo update-rc.d dhcp3-server defaults





[Amazon.com Widgets](http://ws.amazon.com/widgets/q?ServiceVersion=20070822&MarketPlace=US&ID=V20070822%2FUS%2Fsd41net-20%2F8001%2Fd8ee0b28-b036-4f20-a65f-a17d82bc74d4&Operation=NoScript)


That's it! You now have a fully functional DHCP server on your network! Of course, you will need to turn off the DHCP server on your plastic router, if you're using one and haven't already done that. There are some more advanced things you can do with your own DHCP server, which will be the subject of a future post; for now, enjoy the knowledge that your own computer is what lets all the others get on your network and talk to each other.

**Update:** I omitted a few key configuration changes that need to be made for your network to run properly from your DHCP server. These have been added. I have also gone back and added output to many commands, to make it clearer the output we expect to see from them.
