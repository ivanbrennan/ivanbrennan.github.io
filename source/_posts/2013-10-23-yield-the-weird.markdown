---
layout: post
title: "yield the weird"
date: 2013-10-23 22:32
comments: true
categories: ruby yield
---
I'm messing around with `yield` to get a handle on the various closures in Ruby, and I built a method that returns a rotated-mapped array. You could of course do this with the built-in `#rotate` and `#map` methods, but what fun would that be?
```ruby
def rotomap(arr, n)
  arr.each_index.inject([]) do |roto, i|
    roto << yield( arr[ (i+n) % (arr.count) ] )
  end
end

rotomap([1,2,3,4,5], 3) { |x| "#{x * 5} merge requests" }
# => ["20 merge requests", "25 merge requests", "5 merge requests", "10 merge requests", "15 merge requests"]
```
I don't imagine there's a lot of rotomapping going on out there, but it was fun to slap this together.
