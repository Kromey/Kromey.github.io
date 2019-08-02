---
author: admin
comments: true
date: 2015-01-10 03:50:51+00:00
layout: post
link: https://kromey.us/2015/01/pypi-doesnt-like-your-markdown-685.html
redirect_from: /2015/01/pypi-doesnt-like-your-markdown-685.html
slug: pypi-doesnt-like-your-markdown
title: PyPi Doesn't Like Your Markdown
wordpress_id: 685
categories:
- How-to
tags:
- guide
- pet peeves
- python
---

I've been putting all my projects onto [GitHub](https://github.com/Kromey), and as part of that I've gotten used to using ([GitHub-flavored](https://help.github.com/articles/github-flavored-markdown/)) [Markdown](http://daringfireball.net/projects/markdown/) to produce my README files. And it was good!

Now I have [a project](https://github.com/Kromey/django-simplecaptcha) that I'm getting ready to publish to [PyPi](https://pypi.python.org/pypi). Which is a great service, but it comes with a significant handicap: Your documentation needs to be in reStructuredText.

I don't like reStructuredText. With Markdown, your files read quite easily without any formatting; fire up vim and point it at your README, and you have no trouble quickly perusing the file. It *feels* natural. reStructuredText, however, is about as difficult to read as the bizarrely-cased name is to type. In fairness the most common markup is quite similar -- if not outright identical -- to Markdown's, but then you jarringly run into `.. code:: python`. Ugh!

Still, if I'm going to use PyPi, and I want my documentation on the site to be anything other than boring plain text, I've got to adapt somehow.

There's complicated solutions out there that aim to let you write your README in Markdown and then convert it on-the-fly into rST when uploading to PyPi. On first glance this might seem like the perfect solution, but then you get into the nitty-gritty "how" of these approaches, and they real quickly begin to look like cutting off your nose to spite your face.

So I decided to just bite the bullet and convert my README from Markdown into rST. (Besides, GitHub has no trouble reading and formatting either, so it makes no difference there.) Fortunately, [Pandoc](http://johnmacfarlane.net/pandoc/) comes to the rescue! The "swiss-army knife" of markup conversions, Pandoc can effortlessly and -- at least for me so far -- flawlessly convert Markdown to reStructuredText. Heck, it can churn out far more complex file formats, this is a walk in the park for it!

Here's how I converted my README.md to README.rst.


    
    
    $ sudo apt-get install pandoc
    $ pandoc --from=markdown --to=rst --output=README.rst README.md
    $ git add README.rst
    $ git rm README.md
    $ git commit
    $ git push
    



Simple! (Note: If anyone actually checks my revision history, I actually tried to [rename my README in Git](https://github.com/Kromey/django-simplecaptcha/commit/baa907bebba4980cce65cb51386c6e8e8e7aa071) first, and then [converted it](https://github.com/Kromey/django-simplecaptcha/commit/9a03a01710b873ef2e35780a7843a29a7c916b6d); the goal was to preserve the file history should someone ever care to run `git log README.rst`, but even doing it this way the log stops at the rename, so while the history of course remains in the repo itself, there's no connection from README.rst to modifications made to its predecessor. Le sigh.)

Going forward, I just have to remember that this README (and, further down the road, others I'm sure) use rST instead of Markdown. Which is annoying, but certainly something I can live with.
