---
layout: post
title: "speedy TDD"
date: 2014-10-27 22:23
comments: true
categories: TDD, ruby
---

Slow-running tests are no good for [TDD](http://en.wikipedia.org/wiki/Test-driven_development). I've been working with a large Rails app that has some bloated, callback-ridden models. Much of the test-suite uses FactoryGirl, and generating test objects for those big models (and their associations) can slow things down to a crawl even if you're not hitting the database. So when a new feature came along, I took the opportunity to write some fast unit-tests in a different style.

## Couch-Surfer
Imagine an app that logs the journeys of world-travellers (lots of them) as they couch-surf around the globe visiting homebody friends. Each traveller periodically sends a postcard to their next host letting them know how far off they are. We have a few persisted models:
``` ruby
class Traveller < ActiveRecord::Base
  has_many :couch_crashes
  has_many :homebodies, through: :couch_crashes

  # lots more code and callbacks...
end

class Homebody < ActiveRecord::Base
  has_many :couch_crashes

  # lots more code and callbacks...
end

class CouchCrash < ActiveRecord::Base
  belongs_to :traveller
  belongs_to :homebody

  # attributes include :arrival_date
end

class Postcard < ActiveRecord::Base
  belongs_to :traveller
  belongs_to :couch_crash
  belongs_to :homebody, through: :couch_crash

  validates_presence_of :traveller, :couch_crash, :distance
  # distance attribute reflects how many miles away
  # the traveller was at the time of mailing
end
```

Each visit, ie. CouchCrash, is scheduled with an `arrival_date`, but these aren't always accurate. It's hard to know ahead of time exactly when a traveller will reach their destination. We'd like to add a feature that, based on the arrival_date and postcards, assesses the status of a visit as either "Far Off", "Approaching", or "Arrived".
