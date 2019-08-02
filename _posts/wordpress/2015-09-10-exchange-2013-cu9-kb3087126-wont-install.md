---
author: kromey
comments: true
date: 2015-09-10 23:47:37+00:00
layout: post
link: https://kromey.us/2015/09/exchange-2013-cu9-kb3087126-wont-install-700.html
redirect_from: /2015/09/exchange-2013-cu9-kb3087126-wont-install-700.html
slug: exchange-2013-cu9-kb3087126-wont-install
title: 'Exchange 2013 CU9: KB3087126 won''t install?'
wordpress_id: 700
categories:
- How-to
- Tech
tags:
- errors
- exchange 2013
- powershell
- windows
---

Microsoft has released update KB3087126 to address some [important security flaws](https://technet.microsoft.com/library/security/ms15-103) in OWA. Upon installing this update into my Exchange 2013 CU9 environment, however, I encountered some significant problems that left some of my servers in a completely non-working state!

My environment consists of 4 Mailbox/CAS servers in a single DAG (each database shared between a matched pair of servers), a 5th CAS server for both DAG witness and as SMTP relay for email generated by other servers, and 2 Edge servers. Installing the update via Windows Update to the 4 combination Mailbox/CAS servers went smooth as butter (although I was already a bit weary of the earlier failure on my CAS-only server and thus installed it separately), but on my CAS-only server and my two Edge servers, it failed miserably, and left my servers non-functional in its wake.

After much consternation, gnashing of teeth, and being yelled at by users on the phone, the reason for the servers being non-functional turned out to be that, like many such updates, it had to stop some services in order to update them; unlike such updates, however, it did not merely stop them: It _disabled the services altogether!_ Worse, when it failed and rolled back changes, it _left these services disabled!_

When this happened on my CAS-only server -- the first one I updated -- I was more interested in getting things running again than I was in recording data; I was more methodical on the Edge servers, however, and thus I can tell you that the disabled services were:




    
  * AppIDSvc

    
  * MSExchangeAntispamUpdate

    
  * MSExchangeDiagnostics

    
  * MSExchangeEdgeCredential

    
  * MSExchangeHM

    
  * MSExchangeServiceHost

    
  * MSExchangeTransport

    
  * MSExchangeTransportLogSearch

    
  * pla

    
  * RemoteRegistry

    
  * Winmgmt



Since I knew going in to these servers that I might find myself in the situation where I'd need to restore services, I had taken a "backup" of the service configuration before I started using the following PowerShell one-liner:


    
    Get-WmiObject win32_service |
        Select-Object name,startmode |
        Export-Csv -Path .\Desktop\service_backup.csv



Thus, as soon as the update failed, I was able to compare this original backup with the current service state, and then restored the services to their previous startup state:


    
    Compare-Object (Get-Content .\service_backup.csv) (Get-Content .\service_backup2.csv) |
        Where-Object { $_.SideIndicator -eq "< =" } |
        Foreach-Object { Set-Service $_.inputobject.split('"')[1] `
            -StartupType $_.inputobject.split('"')[3] }



_(There's some strange string parsing going on here; don't fret about that too much, the gist is that I'm looping through the diff results from the original service state, and applying the old StartupType to those services again. The string parsing just lets me pull the CSV fields out of the diff results; I probably could have, perhaps even should have, used Import-Csv rather than Get-Content and circumvent that mess entirely...)_

A similar one-liner was used to start each of these services up again.

After restoring services to their proper state, I downloaded the standalone package for KB3087126 and tried to install that, but it choked when it couldn't locate the install media for Exchange! This is seriously getting ridiculous, Microsoft: Why do I have to have the install media on hand just to apply a security update?

The standalone package actually prompts for the path to the installer, but since I had deleted it after upgrading to CU9 to conserve disk space, I had to download that again; either point the standalone package to the new path after extracting it, or just extract to the same directory you had originally installed from (fortunately one simply called "EXC CU9" on the desktop, simple enough I could remember it and put it right back where KB3087126 expected to find it somehow). After that (and a second round of restoring services...), the standalone package for KB3087126 installed without a hitch.

Hopefully this will help somebody else out there. The short version:




    
  * KB3087126 installed just fine on my Mailbox/CAS servers

    
  * On my standalone CAS server, and my Edge servers, it not only failed to install, it left several critical services disabled! Only by saving and then restoring the original service states was I able to recover, and then by re-downloading the CU9 installer and extracting it to the same location I originally used to update my servers I was able to successfully install KB3087126.



**Addendum:** As my commenters have pointed out, you can find what the install path originally was by checking the installer log (`C:\ExchangeSetupLogs\ExchangeSetup.log`), and/or modify it by searching your registry for the old path and setting it to a new one. I think it's easier, however, to simply use the standalone KB package, as it will prompt you for the path to the installer when it fails to find it.