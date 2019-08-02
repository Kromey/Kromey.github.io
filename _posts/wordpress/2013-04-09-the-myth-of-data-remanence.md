---
author: kromey
comments: true
date: 2013-04-09 01:30:47+00:00
layout: post
link: https://kromey.us/2013/04/the-myth-of-data-remanence-484.html
redirect_from: /2013/04/the-myth-of-data-remanence-484.html
slug: the-myth-of-data-remanence
title: The Myth of Data Remanence
wordpress_id: 484
categories:
- Security
- Tech
tags:
- data security
---

_Data Remanence, n.
The residual representation of data that remains even after attempts have been made to remove or erase the data._

It's a well-known fact that simply deleting a file on your computer doesn't actually delete the data that was in it from your hard disk; in fact it's rather trivial to use software that can automatically discover and reconstruct often a surprising amount of data you'd long ago deleted. To really remove that data from a disk (e.g. to safely discard, sell, or otherwise give it away), you have to go a step further and wipe it away.

It's only a slightly lesser known fact that to properly wipe a file from your hard drive, you have to use software that overwrites it numerous times; popular methods today include the Schneier 7-Pass, NIST, DoD, and, perhaps most famously, the Gutmann 35-Pass Method, with most modern software implementing at least a few of these different methods.

But with multiple passes comes increased time, and with increased time comes a decrease in people's willingness to do it. So it's worth exploring a critical question, namely: Is it really worth it?

The answer is, perhaps surprisingly, "No."

Before I elaborate, a brief history of the idea of the multiple-pass wipe. It all started in 1996 with a paper published by Dr. Peter Gutmann, ["Secure Deletion of Data from Magnetic and Solid-State Memory"](http://www.cs.auckland.ac.nz/~pgut001/pubs/secure_del.html). While the meat of the paper is extremely technical and probably impenetrable to most people, the crux of it is a proposed sequence of 35 patterns of data -- 8 of them using pseudo-random data -- intended to make retrieval of overwritten data via extremely technical methods such as magnetic force microscopy impossible.

However, Gutmann himself points out that there are two common misunderstandings of his sequence. The first is that for maximum security, the sequence order should be randomized, so that an attacker can't use knowledge of the sequence to peel away the "layers" it invariably leaves behind. The second, and most crucial, is that there is no use case where all 35 patterns are necessary -- each pattern was devised to address only 1 or 2 of 3 physical encoding standards, and only the patterns intended for the target device's encoding are necessary. This takes the sequence down from 35 passes to 23 at most!

On a large hard drive such as what you would find in modern computers, omitting that 12-sequence difference can add up to _hours_ of time saved! For example, using a theoretical sustained 100MB/s write speed -- actually quite zippy! -- wiping a 750GB hard drive would take more than _2 hours per pass!!_ Omitting 12 sequences therefore saves _more than a full day_ from the process of wiping it!!

When a mere 34% reduction in the number of passes used saves more than 24 hours, is it really any wonder so many people are so unwilling to wipe their old hard drives?

Better yet, does the remaining 48-hour process yield results worth the time spent?

The answer is, still, "No."

Again we turn to the work of Dr. Gutmann, who has since updated his original paper with an [epilogue](http://www.cs.auckland.ac.nz/~pgut001/pubs/secure_del.html#Epilogue). In it, he points out that his 35-pass sequence was devised for everything from then-30-year-old, now extinct storage medium to what was currently in use in 1996; the hard drives in use today use complex physical encoding schemes that make even a single "layer" of historical reading virtually impossible. He is joined in this conclusion by NIST, who in 2006 concluded "studies have shown that most of today’s media can be effectively cleared by one overwrite" and "for ATA disk drives manufactured after 2001 (over 15 GB) the terms clearing and purging have converged." [[Source (PDF)](http://csrc.nist.gov/publications/nistpubs/800-88/NISTSP800-88_with-errata.pdf), page 8.]

It is further worth noting that not a single documented case exists of successfully recovering data from a hard drive after even a single overwrite, despite multiple studies attempting to do just that.

So, what does this all mean for you? It means that files you delete that contain potentially sensitive information -- e.g. credit card numbers, passwords -- should instead be "shredded", and that you should always wipe a hard drive before you discard it or throw it away.

It also means that despite all the hype around multiple-pass purging, you really only need to overwrite data once, which makes it completely impossible to recover via software, and even a laboratory-level attack is very unlikely to bear fruit.

There's lots of software available to take care of secure file deletion for you; on Windows I recommend [Eraser](http://eraser.heidi.ie/), which has the added benefit of being able to schedule automatic secure erasure of your recycle bin and even of the free space on your hard drive. If you're on Linux, GNU `shred` can't be beat. Of course, both of these tools use the full 35-pass "Gutmann Method" by default (except Eraser when clearing unused disk space), but both can also be configured to use shorter algorithms.

If you want to wipe a hard drive before getting rid of it, [DBAN](http://www.dban.org/) has several shorter wipe operations it can use, and runs from a bootable CD. Or, if you can hook up your hard drive to a Linux computer, I've written [a small Bash script](https://gist.github.com/Kromey/5306511) that uses GNU `dd` to overwrite your drive with zeroes.

Don't take my word, though -- these recommendations (aside from my own script, of course) are also endorsed by Dr. Gutmann himself. And, if you really want to physically destroy your hard drive, he recommends [DiskStroyer](http://www.diskstroyer.com/Home.html).

A couple of quick myths related to this:
**Myth**: Drilling through the platters physically destroys the hard drive and the data on it.
**Fact**: The only data actually destroyed is the relatively small percentage that the drill bit actually goes through. Any data recovery firm (or really anyone else who can pull apart a hard drive and read the platters directly) can take that drive apart and recover the rest of the data trivially. They can not, however, recover anything from a drive that's been overwritten even one time.

**Myth**: Using a hammer physically destroys the hard drive and the data on it.
**Fact**: Like the previous myth, at best you're slightly inconveniencing a data recovery firm. You again have better results with a single-pass overwrite.

Finally, a couple of caveats about software-based data purging:

First, it doesn't work on flash-based drives, such as portable jump drives or SSDs. Most SSDs do have a hardware-level "secure deletion" command, however manufacturers frequently implement this wrong and therefore it is unreliable. You can achieve pretty good results by "thrashing" the wear-leveling algorithms by filling the entire drive with zeroes (or ones, or random data) a couple of times, but there is likely to still be data left around even after that for someone who can pull it apart and get to the low-level hardware itself. For these devices your best option is to use encryption (e.g. via TrueCrypt _[EDIT: TrueCrypt has, sadly, been abandoned; while there are alternatives, I haven't looked into any of them so I have no recommendation for a replacement.]_) and/or _never_ store unencrypted sensitive data on them. Physical destruction is also a good bet, although you have to pull it apart to get to the flash chip(s) inside and then basically grind them into dust. A drill actually _is_ a good choice here, but only if you can put it through the actual flash chip(s).

Second, it cannot do anything about the data that may be left over in a "bad sector" on the disk drive. Hard drives constantly monitor themselves for defects in their platters and, when one is found, they re-map it so that data that would be written there is instead redirected to a known good location. These bad sectors are impossible to access via software, but can be read by data recovery firms. However, this would amount to a few KBs, and on modern-day multi-hundred-GB and TB drives finding that data in the sea of garbage is most likely to be fruitless.
