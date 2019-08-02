---
author: kromey
comments: true
date: 2009-12-14 04:56:14+00:00
layout: post
link: https://kromey.us/2009/12/networking-201-running-your-own-dns-server-252.html
redirect_from: /2009/12/networking-201-running-your-own-dns-server-252.html
slug: networking-201-running-your-own-dns-server
title: 'Networking 201: Running your own DNS server'
wordpress_id: 252
categories:
- How-to
- Tech
tags:
- bind9
- dhcp
- dns
- guide
- networking
- ubuntu
---

Setting up your own DNS server is an effective way to enable more interaction between systems on your network. While NetBIOS and WINS can enable the same kinds of interactions without requiring users to resort to IP addresses, they often don't work effectively in mixed-system environments (e.g. Windows and Mac computers) or where networks may be connected but yet distinct (such as a satellite office); further, many personal firewall products result in these systems simply not working at all.

Enter DNS, the basic system that makes the internet itself work. Today's post will show you how to set up your own DNS server on your network. We will start with a simple caching-only (aka forwarding-only) set up, and then build upon that to assign DNS entries to systems within your own network.

This post will build upon my previous post, [Networking 201: Running your own DHCP server](/2009/12/networking-201-running-your-own-dhcp-server-229.html), however you don't need to have your own DHCP server to follow along; I will offer alternative suggestions to help you use a different set up at each step that refers to the DHCP server from that post.

This post is using an Ubuntu server, and we will be installing and configuring BIND 9 to serve as our DNS server. I will be installing this on the same server as my DHCP server from the previous post.

The first step, of course, is to install BIND 9. Fortunately for us, this is easy - on Ubuntu, it is as simple as `sudo apt-get install bind9`. Once that's installed, the fun begins.

Since we first want to simply enable DNS queries for the internet at large, we will set up our DNS server as a caching-only - also referred to as "forwarding-only" - server. Doing this means that any queries directed to our server will be first checked against its local cache and then, if not found there, directed out to a more authoritative DNS server to find the answer. Without going into the details of the way DNS is structured, think of it as asking an employee at your local supermarket where to find a particular product; that employee either knows where it is and can direct you there, or will need to ask another employee for the answer. In the case of the latter, the next time a customer asks that employee the same question, he can direct the customer straight there since he now knows the answer himself.

Setting this up in BIND, all we have to do is add our our forwarders to the file `/etc/bind/named.conf.options`; find the forwarders option and change it to this:


    
    // Use OpenDNS to resolve names we can't find ourselves
    forwarders {
      208.67.222.222;
      208.67.220.220;
    };



As the comment mentions, we're using [OpenDNS](http://www.opendns.com/) here; we could easily use [Google](http://code.google.com/speed/public-dns/docs/using.html)'s (8.8.8.8 and 8.8.4.4) or our local ISP's servers instead. I prefer OpenDNS because of the features and functionality it offers via its dashboard.

Let's make sure that's working now. Save the file, then start (or restart if it's already running) BIND:


    
    kromey@gateway:~$ sudo /etc/init.d/bind9 restart
     * Stopping domain name service... bind                                  [ OK ] 
     * Starting domain name service... bind                                  [ OK ]



We'll use the tool `nslookup` to check that our DNS server is now running and properly resolving internet domain names for us by trying out a few different lookups:


    
    kromey@gateway:~$ nslookup - 172.24.0.1
    > google.com
    Server:		172.24.0.1
    Address:	172.24.0.1#53
    
    Non-authoritative answer:
    Name:	google.com
    Address: 74.125.155.147
    ...snip several other answers...
    > kromey.sd41.net
    Server:		172.24.0.1
    Address:	172.24.0.1#53
    
    Non-authoritative answer:
    Name:	kromey.sd41.net
    Address: 72.14.189.224
    > exit



172.24.0.1 is the IP address of my DNS server, so you can see that all of these responses are coming out of my BIND set up. If you get similar results - which is to say, if you can provide a valid domain name and get one or more IP addresses in response - then you've got a successful set up too.

Now that we can lookup internet domain names via our server, let's reconfigure the computers in our network to use it. This is a simple one-line change in our DHCP configuration:


    
    option domain-name-servers 172.24.0.1;



Of course, replace 172.24.0.1 with the IP address of your DNS server. We haven't discussed it yet, but your DNS server needs to be on a fixed IP address; you can either configure that statically (in the same manner as we did for the DHCP server), or you can give it a static DHCP lease (a topic to be covered in a future post). Allowing the IP address to change is a bad idea because the other computers on your network need to be able to consistently find it.

Restart `dhcp3-server` to load the change we just made. The computers on your network won't get this change yet, however - they will need to first renew their DHCP lease, which will be accompanied by this new value. The easiest way to do this on Linux is to restart your networking entirely (`sudo /etc/init.d/networking restart`); on Windows simply issue the command `ipconfig renew` on the Command Prompt.

If you're not using the DHCP server we set up in the previous post, you'll need to update the one you are using: look for a setting such as "name server" or "DNS server". Check your server's documentation for help if you need it. Once you update it, you will need to renew your DHCP lease in the same manner as above. If you cannot modify your DHCP server's settings (for example, if you get your DHCP lease directly from your ISP), check your operating system's documentation for statically assigning your DHCP server.

Both Linux and Windows have the `nslookup` command, so from either system start it with no arguments and verify that you have the correct name server, and that you can resolve DNS names through it:


    
    kromey@odin:~$ nslookup
    > server
    Default server: 172.24.0.1
    Address: 172.24.0.1#53
    > kromey.sd41.net
    Server:		172.24.0.1
    Address:	172.24.0.1#53
    
    Non-authoritative answer:
    Name:	kromey.sd41.net
    Address: 72.14.189.224
    > exit



If your output looks similar to the above, and the "Server:" line shows your DNS server's IP address, then you have properly set it up and are now using your DNS server! Fire up your favorite internet browser, and bask in the knowledge that every time you go to a website, it is _your_ server that is turning that nice readable name into the IP address your computer needs to find that web site.

That's all well and good, but we haven't done anything yet to allow our computers to use our server to talk amongst themselves. Let's do that now - let's add a DNS entry for our DNS server, as well as provide the comparable reverse-lookup entry. This will easily be expandable to add as many entries as you wish, although you should only provide an entry for a computer with a fixed IP.

The first thing to do is to add our two zones - one for our local network, and one for the reverse lookup of the same. Before that, though, we need to choose a suffix, or "zone" in DNS parlance, to use for our local network. We need to be careful that we don't interfere with a real TLD - creating a zone for ".com", for example, would prevent us from being able to lookup any domain name that ended in .com, such as google.com. For this post, I will choose "homenet", but you are free to choose any name you wish.

Open the file `/etc/bind/named.conf.local` and add the following lines:


    
    // Homenet zone
    zone "homenet" {
      type master;
      file "/etc/bind/homenet/forward.db";
    };
    zone "0.24.172.in-addr.arpa" {
      type master;
      file "/etc/bind/homenet/reverse.db";
    };



Let's stop for a moment and break this down. We're adding two zones here - "zones" being the basic organizational blocks in DNS, each one containing one or more DNS entries. The first zone is for "homenet": this will be referenced for any DNS lookups that end with ".homenet", and is where we'll put our DNS names. For now we'll ignore the type line - it's used for DNS replication, which will be a future post; for now just trust me that it should be set to "master". The last option in the zone, file, tells BIND where to go to find the entries for the zone. We'll be looking at this in a moment when we set up our zone files.

The second zone we're adding looks a little weird, doesn't it? We certainly didn't set out to name our network anything like that, right? Well, actually, we did - this is (part of) the standard form of a reverse DNS lookup, where we use an IP address to find the DNS name. Try it out using nslookup - if you query for 72.14.189.224, your response will include the line `224.189.14.72.in-addr.arpa name = sd41.net.`. Now, that looks familiar, doesn't it - quite a bit like our second zone here. If you notice, the address that's looked up consists of the IP address itself, but with the octets in reverse order - 12.34.56.78 becomes 78.56.34.12; the suffix ".in-addr.arpa" is then added onto that. This is how reverse DNS lookups are done, and since we decided to use the subnet 172.24.0.0/24, we did in fact set out from the very beginning to create the zone 0.24.172.in-addr.arpa - we just didn't know it yet.

Okay, so now let's create the files themselves. If you'll notice, I included an extra directory in the file paths above. This is an organizational thing, really, and has no real bearing on life unless you are managing multiple zones on your DNS server. Nonetheless, I do recommend it - makes your life easier if you add zones later, as well as it easily groups your forward and reverse zones together.

So, create the directory, and then create the file `forward.db` inside it with the following contents:


    
    ; Zone file for homenet
    ; 
    $TTL  10800 ; 3 hours
    @ IN  SOA gateway.homenet. kromey.sd41.net. (
          200907101 ; Serial
          3h    ; Refresh
          1h    ; Retry
          4w    ; Expire
          1h )    ; Negative Cache TTL
    
      IN  NS  gateway
    
    gateway  IN  A 172.24.0.1
      IN  TXT "DHCP and DNS server"



We're going to ignore most of the header for now - that will be examined in a future post dealing with more advanced uses of a DNS server. Also, this post is already pretty long - I don't get paid by the word here! (Hm, actually, I don't get paid here at all...) The only line we're going to pay any attention to is the SOA, or Start Of Authority, record. The two pieces you should be concerned with right now are



	
  * _gateway.homenet._ - This needs to be the DNS name for the authoritative DNS server for the zone (that's this server); don't forget the trailing period.

	
  * _kromey.sd41.net._ - This is the e-mail address of the DNS administrator (you), with the @ symbol replaced with a period; when translating this back into an e-mail address, the first period is assumed to be the @ character. What if your e-mail address contains a period? Good question - I don't know the answer. Again, though, don't forget the trailing period.



So now that we've addressed the SOA record, let's move on to the first DNS entry - `IN NS gateway`. "IN" means "internet", and is called the "class" of the record. There are other classes, but don't worry about them now - we just want internet records. "NS" stands for name server; there should be one NS record for each name server that can answer queries about your zone (for now, that's just this one - we'll add a redundant one in a later post). Finally, the last part of this record is "gateway"; this is because I chose to name my server "gateway.homenet". So, where's "homenet"? It's implied: Notice that there is no trailing period on this one - if there is no trailing period, the zone name ("homenet" in this case) is appended to the name ("gateway") to produce the FQDN ("gateway.homenet"). Don't worry if that doesn't all make sense right now - I'll explain this in more detail when I cover advanced DNS topics in a later post. For now, just trust me that this works.

The next record, `gateway  IN  A 172.24.0.1`, is the A (for "address") record, which is what maps a DNS name you can more easily remember to an IP address that your computer can actually use to find the computer. Similar to the NS record above, I used "gateway" (no trailing period) as the name, which means that this will match queries for "gateway.homenet". The IP address is the one that I chose for my server. The last record, `IN  TXT "DHCP and DNS server"`, will be discussed in a future post. For now, just think of it as a one-line memo field.

Now save that file, and then create `/etc/bind/homenet/reverse.db` with the following contents:


    
    ; Reverse zone file for Homenet
    ; 
    $TTL  10800 ; 3 hours
    0.24.172.in-addr.arpa. IN  SOA gateway.homenet. kromey.sd41.net. (
          200907101 ; Serial
          3h    ; Refresh
          1h    ; Retry
          1w    ; Expire
          1h )    ; Negative Cache TTL
    
      IN  NS  gateway.homenet.
    
    1 IN  PTR gateway.homenet.



The SOA record should look familiar, although note that it starts differently here. In the first file, it began with the single character "@", whereas here it's beginning with "0.12.10.in-addr.arpa.". The "@" character is expanded when the zone file is read to be the name of the zone itself, so that SOA record in our first file could have begun with "homenet." instead and would have been exactly equivalent. So why didn't I use the "@" character here? Well, how else would I get to explain its use and purpose?

The NS record now references "gateway.homenet." instead of "gateway"; remember, the zone name is appended when no trailing period is present; the previous zone file was for the "homenet" zone, whereas this one is not, which is why we've added the domain and the trailing period here. So these are in fact identical records, which shouldn't come as a surprise - this zone is the complement of the first one we created, so its NS records should match those in the first.

The final record looks different, though - we haven't seen a PTR record before. "PTR" is an abbreviation of "pointer", and is just that - a pointer from an IP address to a DNS name. The first part is, simply, the digit "1". Remember that since it doesn't end with a period, the name of the zone (in this case, "0.24.172.in-addr.arpa") is appended to it, so we end up with 1.0.24.172.in-addr.arpa - exactly what we want to look for when doing a reverse DNS lookup for the IP 172.24.0.1. This PTR record points us to the domain name "gateway.homenet." (note the trailing period!); this one happens to be the exact opposite of the A record we created earlier, but that is not always the case - imagine, for example, a web server that hosts many sites (and therefore has many domain names pointing to it). We can only have a single PTR record for a given IP, however, so the reverse DNS lookup can only ever give us 1 DNS name, no matter how many DNS names actually point to the server. You can see that on this server, in fact: using `nslookup`, find the IP address behind kromey.sd41.net, and then type that IP address into `nslookup` and see what you get (the observant reader will have already noticed this earlier in this post).

Okay, we've come a long way, but we're at last done. All that's left is to restart BIND, and then test out our server with `nslookup`.


    
    kromey@gateway:~$ sudo /etc/init.d/bind9 restart
     * Stopping domain name service... bind                                  [ OK ] 
     * Starting domain name service... bind                                  [ OK ]
    kromey@gateway:~$ nslookup gateway.homenet
     ...snip...
    Name:	gateway.homenet
    Address: 172.24.0.1
    kromey@gateway:~$ nslookup 172.24.0.1
     ...snip...
    1.0.24.172.in-addr.arpa	name = gateway.homenet.



One last thing before we part ways. Since we've decided that all of our computers on our network will be within the .homenet domain, wouldn't it be nice if we could have a shortcut for that? Well, thanks to our DHCP server, we can! Edit `/etc/dhcp3/dhcpd.conf` and add this line after your name server option:


    
    option domain-name "homenet";



This tells any computer that receives a DHCP lease from our server that it is within the .homenet domain. This means that our DNS lookups can omit that part from the address. (To accomplish this same effect with a different DHCP server, look for a setting like "domain" or "domain name"; refer to your DHCP server's documentation. If you cannot change settings on your DHCP server, you're out of luck for this feature, I'm afraid.) To see this in action, restart your DHCP server, and then renew your DHCP lease before firing up `nslookup` one more time:


    
    kromey@gateway:~$ nslookup gateway
     ...snip...
    Name:	gateway.homenet
    Address: 172.24.0.1





[Amazon.com Widgets](http://ws.amazon.com/widgets/q?ServiceVersion=20070822&MarketPlace=US&ID=V20070822%2FUS%2Fsd41net-20%2F8001%2Fca8d753c-40fb-4c5d-81dd-3bac58c7e4ea&Operation=NoScript)


Look at that! Our .homenet domain was appended as if by magic!

Now that we've got our DNS server up and running beautifully, you can add more DNS entries if you have more computers with static IP assignments. In a later post, we'll use static DHCP leases to accomplish the same thing, but with the added benefit of central management.
