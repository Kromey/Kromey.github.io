---
author: admin
comments: true
date: 2011-05-25 03:19:54+00:00
layout: post
link: https://kromey.us/2011/05/changing-an-exchange-user-mailbox-to-a-resource-411.html
redirect_from: /2011/05/changing-an-exchange-user-mailbox-to-a-resource-411.html
slug: changing-an-exchange-user-mailbox-to-a-resource
title: Changing an Exchange User Mailbox to a Resource
wordpress_id: 411
categories:
- How-to
tags:
- exchange server
- guide
- windows
---

[Creating a resource mailbox](http://blogs.technet.com/b/exchange/archive/2007/05/14/3402515.aspx) in Exchange Server is easy. And it can make managing your organization's resources -- conference rooms, projectors, etc. -- real easy, especially in avoiding double-booking.

But what if you accidentally create your resource mailbox as a user, instead? You can't set it to auto-accept invitations, creating a management nightmare as each one has to be manually accepted on your resource's calendar.

You can change the type of the account, but no one -- Microsoft included -- makes it easy to find out how! Here's my humble effort to change that...

If you create your resource using the `New-Mailbox`, you simply specify "-Room" as one of the arguments, and Bam! you have yourself a room resource.

But what if you forget that part?


    
    
    [PS] C:\Windows\system32>Get-Mailbox confroom |fl *resource*
    
    IsResource       : False
    ResourceCapacity :
    ResourceCustom   : {}
    ResourceType     :
    
    [PS] C:\Windows\system32>Get-MailboxCalendarSettings confroom
    
    AutomateProcessing                  : AutoUpdate
    



Well, that won't do -- we want AutoAccept, not AutoUpdate; the latter puts meeting invites in the "Tentative" state, while the former actually accepts them, which is what we want. But we can't change it to AutoAccept because it's not a resource!

Okay, well, `New-Mailbox` uses the "-Room" parameter, so all we need to do is to use `Set-Mailbox` with that parameter, right?

Wrong. Microsoft, in their infinite wisdom, decided that they don't need consistency. So how do you do it?


    
    
    [PS] C:\Windows\system32>Set-Mailbox confroom -type room
    [PS] C:\Windows\system32>Set-MailboxCalendarSettings confroom -AutomateProcessing:AutoAccept
    



Easy, huh? Wouldn't it have been easier, though, if Microsoft had embraced the very simple philosophy of consistency?
