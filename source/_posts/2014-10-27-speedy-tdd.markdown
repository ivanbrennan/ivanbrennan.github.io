---
layout: post
title: "speedy TDD"
date: 2014-10-27 22:23
comments: true
categories: TDD, ruby
---

Slow-running tests are no good for [TDD](http://en.wikipedia.org/wiki/Test-driven_development). I've been working with a large Rails app that has some bloated, callback-ridden models. Much of the test-suite uses FactoryGirl, and generating test objects for those big models (and their associations) can slow things down to a crawl even if you're not hitting the database. So when a new feature came along, I took the opportunity to write some fast unit-tests in a different style.

### Couch-Surfer
Imagine an app that logs the journeys of world-travellers (lots of them) as they couch-surf around the globe visiting homebody friends. Each traveller periodically sends a postcard to their next host to let them know how far off they are. We have a few persisted models:
``` ruby
class Traveller < ActiveRecord::Base
  has_many :couch_crashes
  has_many :homebodies, through: :couch_crashes

  # lots more associations, validations, and callbacks...
end

class Homebody < ActiveRecord::Base
  has_many :couch_crashes

  # lots more associations, validations, and callbacks...
end

class CouchCrash < ActiveRecord::Base
  belongs_to :traveller
  belongs_to :homebody
  has_many :postcards

  validates_presence_of :traveller, :homebody, :arrival_date
end

class Postcard < ActiveRecord::Base
  belongs_to :traveller
  belongs_to :couch_crash
  belongs_to :homebody, through: :couch_crash

  validates_presence_of :traveller, :couch_crash, :distance
  # distance reflects how many miles away
  # the traveller was at the time of mailing
end
```

Each visit, ie. CouchCrash, is scheduled with an `arrival_date`, but these aren't always accurate. It's hard to know ahead of time exactly when the traveller will reach their destination. We'd like to add a feature that, based on the arrival_date and available postcards, assesses the status of a visit as "far off", "approaching", or "in progress". We won't bother with a "completed" status since those couch-crashers have been known to stick around forever.

For simplicity's sake, we'll say an "approaching" status requires a postcard from within 100 miles and "in Progress" requires one within 5 miles (I know, that's a waste of a stamp). Otherwise, with either no postcards or only those over 100 miles away, the visit is "far off".

If we used FactoryGirl, an initial spec might look something like:

```ruby
describe CouchCrash do
  let(:visit) { FactoryGirl.build(:couch_crash) }

  describe '#status' do
    subject(:status) { visit.status }

    context 'with a postcard from 100 miles away' do
      it 'is "approaching"' do
        postcard = FactoryGirl.build(:postcard, distance: 100)
        visit.stub(:postcards).and_return([postcard])

        expect(status).to eq(:approaching)
      end
    end
  end
end
```

We've managed to avoid hitting the database by using `build` rather than `create` and stubbing the association between `visit` and its postcards. On the surface, it looks like a well-isolated test that should run quickly, but let's take a closer look at the factories we're using:

```ruby
# spec/factories/couch_crashes.rb
FactoryGirl.define do
  factory :couch_crash do
    traveller
    homebody
    arrival_date 2.weeks.from_now
  end
end

# spec/factories/post_cards.rb
FactoryGirl.define do
  factory :post_card do
    traveller
    couch_crash
    distance 300
  end
end
```

It's best practice to define your factories with the minimum set of attributes necessary to produce a valid object. (You don't want to set land-mines for the next developer that comes along and calls `create`.) The couch_crashes factory, therefore, creates traveller and homebody test objects, hitting the database and using factories for two of our most bloated models. FactoryGirl does allow you to build the association without saving:

```ruby
factory :couch_crash do
  association :traveller, strategy: :build
  association :homebody,  strategy: :build
  ...
```

In our case though, we'd like to avoid even building those objects if we can. A glace at their factories shows how much unnecessary bulk they'd be adding to the specs:

```ruby
# spec/factories/travellers.rb
FactoryGirl.define do
  factory :traveller do
    first_name "Stewey"
    last_name  "Louis"
    association :hometown, factory: :city
    luggage
    bicycle
    
    after(:build) do |traveller|
      pump = FactoryGirl.build(:bicycle_pump)
      traveller.bike_pump = pump
      traveller.inflate_tires
      traveller.pack_luggage
      traveller.buy_stamps
      ... # you get the idea ...
  end
end

# spec/factories/homebodies.rb
FactoryGirl.define do
  factory :homebody do
    first_name "Joe"
    last_name  "Stumps"
    house
    couch
    spouse
    dog
    credit_score 400
    car
    # again, you get it ...
  end
end
```
