---
layout: post
title: "karabiner"
date: 2015-06-06 14:45
comments: true
categories: ergonomics, keyboard
---

A while back I stopped using "jk" to exit Vim's insert-mode, turning instead to the mostly-useless `Caps Lock`. I set it to be `Control`, then used [Karabiner](https://pqrs.org/osx/karabiner/) to turn it into a dual-purpose `Control`/`Escape`. Typed by itself, it's `Escape`; in concert with another key it's `Control`. The boost in comfort and productivity has been huge.

Bringing `Escape` closer to home feels like a more sensible solution, and I'm no longer typing "jk" all over the place when my fingers forget they're not in Vim. The productivity gains, however, are largely the result of having a `Control` key that's so accessible. It's opened up my use of control-modified commands like Vim's autocompletion and the shell's reverse-incremental-search quite a bit.

To set this up on OS X, first go to the Keyboard pane of System Preferences and change `Caps Lock` to `Control`.

{% img caps-lock /images/karabiner/caps-lock.png 'caps-lock' %}

Then use Karabiner to send `Escape` when you type `Control` by itself.

    * karabiner preferences -> "Change Key" tab
    * scroll down to "Change Control_L Key (Left Control)"
    * check "Control_L to Control_L (+ When you type Control_L only, send Escape)"

{% img escape /images/karabiner/escape.png 'escape' %}

## More Control

I recently took this one step further and turned my `Return` key into a dual-purpose `Control`/`Return`, giving me easy access to a `Control` key on either side of the keyboard.

{% img return /images/karabiner/return.png 'return' %}
