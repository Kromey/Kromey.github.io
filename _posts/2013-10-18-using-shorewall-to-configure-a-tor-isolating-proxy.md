---
author: admin
comments: true
date: 2013-10-18 04:25:07+00:00
layout: post
link: https://kromey.us/2013/10/using-shorewall-to-configure-a-tor-isolating-proxy-584.html
redirect_from: /2013/10/using-shorewall-to-configure-a-tor-isolating-proxy-584.html
slug: using-shorewall-to-configure-a-tor-isolating-proxy
title: Using Shorewall to configure a Tor isolating proxy
wordpress_id: 584
categories:
- How-to
tags:
- anonymity
- firewall
- guide
- linux
- networking
- nsa
- shorewall
- tor
---

[Tor](https://www.torproject.org/) is great for browsing the internet anonymously. But, it's not perfect -- rogue software on your machine can compromise your identity and reveal who you are by simply sending its own network traffic. If you can isolate your machine, however, and guarantee that all network traffic goes through Tor, you greatly improve your odds of maintaining your anonymity online.

This is known as an "[isolating proxy](https://trac.torproject.org/projects/tor/wiki/doc/TorifyHOWTO/IsolatingProxy)", and using [Shorewall](http://www.shorewall.net/) it is actually quite simple to configure one yourself.

First, let's clarify what we're discussing here. You can configure your machine so that all outbound traffic is sent through Tor, and that only Tor itself can make direct outbound connections. This is a "[transparent proxy](https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy)", and while quite good there are a [variety of problems](https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxyLeaks) with it that make it a much weaker alternative than what we'll be discussing here.

In contrast, an isolating proxy is physically separate from your machine, and intercepts all network traffic coming from your machine and sends it into Tor. The biggest advantages are the addition of physical layers preventing your machine from knowing your public IP address, as well as the guarantee that rogue software on your machine can't find a way around -- or reconfigure by itself -- your transparent proxy setup. This is generally accomplished via a securely isolated physical or virtual network, the configuration of which will not be discussed here (but may be the subject of a future post).

This post is also not a tutorial for installing and setting up Tor or Shorewall; instead, I assume both are already installed and running. From here on out, "your machine" refers to the machine you are isolating, while "the proxy" will refer to the machine intercepting your network traffic and directing it into the Tor network.

So we are assuming that your machine is on a private, isolated network, and that the only physical link from it to the outside world is by going through the proxy; in other words, your typical private network. It would be easy to use Shorewall to configure your proxy as a simple NAT router, but we're not going to do that; instead we are going to use Shorewall to proxy all of your connections through Tor.

To do this, first we must ensure Tor is set up to handle this type of proxying; by default it is only a SOCKS proxy, which is good but that's not what we need. We need a transport proxy and, while we're at it, a DNS proxy. Fortunately, Tor makes this easy:

    
    TransPort 9040
    TransListenAddress 172.16.0.1
    DNSPort 52
    DNSListenAddress 172.16.0.1


The first two lines set up our general transport proxy on port 9040, listening on the IP address 172.16.0.1; the next two set up Tor's DNS proxy on port 52 of the same IP address.

Why did I use port 52 for the DNS, rather than the default DNS address of port 53? Because in my case my proxy also serves a separate network, and has the rather lazily-configured 0.0.0.0:53 listen address for its DNS service. If I told Tor to use the same port, I'd get a conflict in one or the other, and rather than reconfiguring my DNS server I simply chose a different port. It doesn't matter anyway what port we choose; Shorewall will take care of this for us.

In fact, let's start configuring Shorewall now. We first start in the `interfaces` file; for me my isolated Tor network is connected on eth2, so I add the following line:

    
    #ZONE    INTERFACE    BROADCAST    OPTIONS
    tor      eth2         detect       dhcp


The DHCP isn't strictly necessary in my case, since I'm using statically-assigned IPs for this network, but if yours uses DHCP you'll need this. Note that I've named my zone `tor`; the internet zone is named `net`. Oh, and don't forget to add it to your `zones` file:

    
    #ZONE    TYPE
    tor      ipv4



Now, we want a default policy that flat out prohibits any and all connections from our `tor` zone to, well, _anywhere_. Easy enough to add to our `policy` file:

    
    #SOURCE    DEST    POLICY    LOG LEVEL
    tor        net     REJECT    info
    tor        $FW     REJECT    info


We could have simplified this to a `tor2all` policy, or even use a restrictive `all2all` policy and let that handle this for us, but I like breaking things out like this, especially as it makes it easier to tweak later if, for example, I wanted to allow my machine to access my proxy (which would weaken the isolation, so don't actually do that). You might be tempted to change these policies to `DROP` to prevent any rogue software on your system figure out that your proxy exists, but since our machine has to know about its gateway anyway this doesn't actually gain us anything; but definitely do `DROP` anything coming in from the big bad `net` zone!

That's the initial busy-work done; now the actual meat of this little setup -- and it's surprisingly easy! Just open up your rules file and add these two lines:

    
    #ACTION    SOURCE    DEST    PROTO    DEST PORT
    #Redirect DNS requests into Tor's DNS proxy
    REDIRECT   tor       52      udp      53
    #Redirect everything else into Tor's network
    REDIRECT   tor       9040    tcp


That's it? That's it! Restart Shorewall, ensure Tor's running properly, and you're good to go! All network requests made on your `tor` network through this proxy (configured as the gateway in your IP configuration, of course) will be forced into and through Tor's network. This is the strongest way to ensure your anonymity with Tor that I know of, and indeed Tor's own documentation suggests that an isolating proxy is the strongest solution.

For my part, I do my anonymous browsing from within a virtual machine, configured to use a private virtual network that my proxy VM is also on; the proxy has a second network interface configured to NAT through my host, which itself is behind a NAT router. That's 3 physical layers between my anonymous VM and my public IP address, all of which are completely off-limits to my browsing VM thanks to these secure firewall rules! Additionally, I have a snapshot of my VM that I routinely revert to after browsing with it; while not quite as good as strictly running from read-only media (such as a live CD), it would be very difficult for even the NSA to get in there with anything that sticks around longer than a single session, and quite difficult for them to accomplish anything while they're there anyway thanks to my isolating proxy that isn't even accessible to my browsing VM!

I will probably write up additional posts with more ways to stay safe, secure, and anonymous online in the future. Yes, I'm jumping on the anti-NSA spying bandwagon here, but it's good stuff to know and the current climate is practically begging for this information to be shared.
