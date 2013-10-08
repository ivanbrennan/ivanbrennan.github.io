---
layout: post
title: "Enumerables"
date: 2013-10-08 08:38
comments: true
categories: ruby
---
Ruby provides lots of built-in methods for working with arrays, but at first glance, some seem to be missing from the [Array documentation](http://ruby-doc.org/core-2.0.0/Array.html). A good example is the `#find` method, which returns the first element satisfying the criteria you provide in a block.

    [1,2,3,4,5].find { |x| x > 2 }  # => 3

The fact is, these methods are mixed in from the [Enumerable module](http://ruby-doc.org/core-2.0.0/Enumerable.html), a collection of useful methods that can be applied to Arrays, Ranges, and Sets, among other Ruby classes. A simple check `whatever_object.is_a? Enumerable` will confirm whether whatever object your dealing with includes the Enumerable module.

One of these methods, `#zip`, has been calling out to me since I started learning Ruby. It seemed like an alchemical process that merged arrays in a mysterious way. In practice, it simply merges the corresponding elements of each array, returning an array of arrays.

    i_got   = ["I got the style",
               "I got the clothes",
               "I got the bread",
               "I got the winda"]

    but_not = ["but not the grace",
               "but not the face",
               "but not the butter",
               "but not the shutter"]

    i_got.zip(but_not)
    # => [["I got the style", "but not the grace"],
          ["I got the clothes", "but not the face"],
          ["I got the bread", "but not the butter"],
          ["I got the winda", "but not the shutter"]]

Pretty nice, but why don't we do [Tom Waits](http://www.youtube.com/watch?v=ByomIJf5n9w) proud and join those phrases?

    i_got.zip(but_not) {|got_not| got_not.join(", ")}
    # => nil

Whoops! Passing `#zip` a block will invoke the block for each output array, but return `nil` at the end of the day. A call `#map` to will do the trick.

    i_got.zip(but_not).map {|got_not| got_not.join(", ")}
    # => ["I got the style, but not the grace",
          "I got the clothes, but not the face",
          "I got the bread, but not the butter",
          "I got the winda, but not the shutter"]

In fact, `#zip` can merge any number of arrays...

    bagels  = ["sesame bagel",
               "plain bagel",
               "poppy bagel",
               "pumpernickel bagel"]

    spreads = ["cream cheese",
               "butter",
               "peanut-butter",
               "jam"]

    extras  = ["lox",
               "tomato",
               "chives",
               "lettuce"]

    bagels.zip(spreads, extras).map do |bgl, spd, xtr|
      "#{bgl} with #{spd} and #{xtr}"
    end
    # => ["sesame bagel with cream cheese and lox",
          "plain bagel with butter and tomato",
          "poppy bagel with peanut-butter and chives",
          "pumpernickel bagel with jam and lettuce"]

Not all the tastiest combinations, but that's how `#zip` works, it just matches up the elements in whatever order they appeared in the original arrays.