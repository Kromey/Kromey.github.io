---
author: admin
comments: true
date: 2014-01-18 03:05:33+00:00
layout: post
link: https://kromey.us/2014/01/when-git-bites-back-624.html
redirect_from: /2014/01/when-git-bites-back-624.html
slug: when-git-bites-back
title: When Git Bites Back
wordpress_id: 624
categories:
- Tech
tags:
- fail
- git
- pet peeves
---

I love Git. Before I discovered version control, I lived a dangerous cowboy-coder life, and I loved that. But then I was introduced to Subversion, and I saw that this was better. Then, I met Git, and saw that is was better still -- best, even!

Recently I discovered the one thing SVN does better than Git: with SVN you can checkout only a subdirectory of a repository; with Git, you must check out all, or nothing. Oh well, Git's light, having multiple repositories doesn't hurt.

But most recently -- today -- Git bit me right in the arse. And I am not happy about the hundreds of lines of lost code. Not. One. Bit.

Recently a friend of mine -- [Jon](http://jonmsawyer.com/) -- got me using [GitHub](https://github.com/) with more regularity (read: at all!), and I've been on a kick of slowly adding old scripts and things I want to keep and/or share. So when I stumbled upon an old Boggle solver -- a script I wrote for an in-house coding competition 4 years ago, and the winning submission in fact -- well, naturally, I went right to GitHub, made the repository, and began the process of committing my script.

Normally, when you're creating a new GitHub repository for existing code, the process goes like this:



	
  1. Create GitHub repository

	
  2. `git init` in your existing directory

	
  3. `git remote add origin git@github.com:...` to connect it to GitHub

	
  4. `git pull origin master`

	
  5. `git add` and `git commit` to add your code, update your license and readme, etc.

	
  6. `git push origin master` to get it all back onto GitHub



This pretty much guarantees a minimum of 5 separate commits just to put your code onto GitHub. I mean, there's nothing _wrong_ with that, but being somewhat OCD I decided to try and "fix" that:



	
  1. Create GitHub repository

	
  2. `git init` in your existing directory

	
  3. `git add file1 file2 file3`

	
  4. `git remote add origin git@github.com:...` to connect it to GitHub

	
  5. `git pull origin master`



...and that's where it hit the fan!

After the pull, I did a quick `git status` to check on my code -- not being sure if the pull would unstage files or not. They didn't show up there. "Oh well, no biggie," I thought, and went to add them back in.

They weren't there. My files were completely gone, entirely erased from the file system!

Git erased my code from existence!!

Fortunately I had a (slightly stale/out-dated) copy hanging out in my e-mail for the major script, but the minor script that went with it was irrevocably gone forever, until I rewrote it from scratch.

After I brought him up to speed, Jon decided to do his own tests. After confirming what I saw -- staged but uncommitted files in an otherwise virgin repository do get erased from the file system entirely when doing `git pull origin master` -- he tried the same thing with staged-but-uncommitted files in a local repository that had a commit, but had not yet reached out to the GitHub remote; the results there were more in line with how I would expect Git to behave, namely it did _not_ erase them from the file system, and even threw an error ("Your local changes to the following files would be overwritten by merge") before aborting the pull altogether.

So it seems this danger is limited to fresh, completely virgin local repositories that you're connecting to a remote for the first time.

Still, in the future, I'll pull first, then add and commit. And I'll always double-check `git status` before any pull, and never pull with staged-but-uncommitted changes, whether my local repository is virgin or not.
