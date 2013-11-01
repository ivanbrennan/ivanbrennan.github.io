---
layout: post
title: "Other People's Dotfiles (OPD)"
date: 2013-11-01 02:21
comments: true
categories: dotfiles git
---
After getting familiar with Git and the concept of version control, I got interested in backing up my dotfiles (`.bash_profile`, `.vimrc` and the like), most of which were in `~`. Now, turning my entire home directory into a Git repository would be asking for trouble, but a classmate suggested I might use symlinks to get around this.

The basic idea is this: move your dotfiles into their own directory, link to them from their original locations, ensuring they're still available to the applications that need them, and run `git init` with a little less trepidation.

I did some googling and found I'm not the first to think of [this](http://dotfiles.github.io). There are some pretty advanced scripts out there for backing up your dotfiles this way, but I wanted to do it myself since I wasn't backing up that many files and I wanted to understand how it worked. The consensus seems to be to use symlinks, which begs the question: what's the difference between a symlink (or "soft link"), and a hard link?

What we think of as a filename is actually a pointer to a specific location in memory. If we have a file `~/goblet`, pointing at memory location-X, we could create a hard link to the same location with a different name, say `~/Stockpile/golden_cup`. Both `~/goblet` and `~/Stockpile/treasure/golden_cup` point directly at the same location in memory. We could instead create a symlink `~/Cloud/chalice` pointing at `~/goblet`, which in turn points to location-X in memory.

It's a subtle distinction, but one that carries real repercussions. If we move or delete the original `~/goblet`, then the hard link `~/Stockpile/golden_cup` will still point at the same data (moving another pointer has no effect on this pointer), but the symlink will be broken. It just pointed at the original path (`~/goblet`), and now it's connection to the memory location is severed.

Despite this apparent disadvantage to symlinks, the general consensus seems to be to prefer them for linking to dotfiles. They do offer the ability to link across separate filesystems, and besides, I'm not planning on moving them around, so I went ahead and made some symlinks to serve my purpose.

Take, for example, my `~/.bash_profile`. I created a directory for my dotfiles at `~/Development/resources/dotfiles/`, moved the file to that directory, and linked to it with a symlink from its original location in `~`, allowing my shell to pick it up at the expected location (`~`).

    mkdir -p ~/Development/resources/dotfiles/
    mv ~/.bash_profile ~/Development/resources/dotfiles/bash_profile
    ln -s ~/Development/resources/dotfiles/bash_profile ~/.bash_profile

I removed the `.` from the target filename both for convenience (so it shows up in Finder), and to distinguish it from the symlink I created at `~/.bash_profile`. Then I initialized a git repository in the `dotfiles` directory, putting my precious dotfiles under version control and making it easier to share them.
