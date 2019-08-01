---
author: admin
comments: true
date: 2014-08-06 20:02:00+00:00
layout: post
link: https://kromey.us/2014/08/creating-a-dag-in-exchange-2013-on-server-2012-r2-653.html
slug: creating-a-dag-in-exchange-2013-on-server-2012-r2
title: Creating a DAG in Exchange 2013 on Server 2012 R2
wordpress_id: 653
categories:
- How-to
tags:
- exchange
- exchange 2013
- fail
- guide
- pet peeves
- windows
---

If you try and create a Database Availability Group using the EAC -- and hope to use that new-fangled feature of creating one without an IP address -- _you will fail_, and neither Microsoft's documentation nor any of the myriad TechNet blogs will help you one whit.

Worse, your entire AD structure will be in such a state that manual intervention and cleanup of the garbage Exchange created will be necessary -- but, again, no one will bother to tell you that!

If you're like me and setting up a brand new Exchange 2013 infrastructure on Server 2012 R2, you'll have it in your head that you should likewise be using the latest features available in Microsoft's leading-edge products, such as a DAG without an administrative access point, a "feature" that never really offered any advantage in the first place anyway.

The EAC lures you in with false promises of making DAG creation easy, but in this scenario it will lead you down a path of failure littered with uselessly vague error messages. But of course none of that will show up until you've "successfully" created your DAG, and now you're just trying to add your first mailbox server to it!

The first error you'll see will be an "access denied" error. Oh, but it's okay -- it's a "transient error", we'll just retry! "The fully qualified domain name for node 'DAG1' could not be found."

Dare to Google that one, and you'll find only resources telling you to pre-stage the CNO for your DAG in AD. But wait a minute -- that's not necessary for Server 2012 R2 and without an administrative access point! So what's the deal?

Ah! The EAC has lead you astray -- your DAG is _not_ created as you wanted it to be -- it _does_ have an administrative access point, and thus _does_ need a pre-staged CNO in order for it to work.

So, let's delete the DAG and turn instead to the EMC, and get it done this way.

    
    
    [PS] C:\>New-DatabaseAvailabilityGroup -Name DAG1 -DatabaseAvailabilityGroupIPAddresses ([System.Net.IPAddress]::None) -WitnessServer WITNESS
    You must provide a value for this property.
    



Oh what now, Exchange? What property do you want a value for?

This is where I banged my head for a _long_ time before finally finding the answer: The bogus CNO from your previous attempt at creating your DAG is still hanging out in your AD structure! Head on over to ADUC, look inside Computers, and delete it.

Now you can happily create your DAG -- _without_ that bloody access point! -- and get on with your day:

    
    
    [PS] C:\>New-DatabaseAvailabilityGroup -Name DAG1 -DatabaseAvailabilityGroupIPAddresses ([System.Net.IPAddress]::None) -WitnessServer WITNESS
    [PS] C:\>Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer MBX1
    [PS] C:\>Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer MBX2
    [PS] C:\>Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer MBX3
    [PS] C:\>Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer MBX4
    



To sum up, these are the useless error messages you'll see in this scenario, along with what they _actually_ mean:



	
  * **"...operation failed with a transient error... Error: Access is denied"** You've tried to add a server to a DAG that, despite the happy "success" state it appears to be in, has a bogus configuration for its access point and a screwed-up CNO in AD. Because you dared to believe Microsoft's own documentation when they said that pre-staging the CNO isn't necessary, and then trusted the EAC to do what it says it can do.

	
  * **"The fully qualified domain name for node 'DAG1' could not be found."** You foolishly believed Exchange's previous message that calls it a "transient" error, and you re-tried adding the server. The CNO is basically fully borked at this stage. Time to just remove it and try again.

	
  * **You must provide a value for this property.** Winning both awards for Vaguest Error Message and Most Useless Error Message, this one means that you deleted your DAG above and tried to re-create it. The problem? Exchange doesn't bother cleaning up after itself, and that fully-borked CNO is still cluttering up your AD and prohibiting you from re-creating the DAG. Either pick a new name, or hop into ADUC and delete it.



I've never been one to favor a GUI over the good-old command line, but if you're going to offer a GUI that claims to do a job, make it work for that job! Dammit, Microsoft, how is this such an alien concept??
