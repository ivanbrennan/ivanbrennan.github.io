---
layout: post
title: "Faster Specs"
date: 2014-10-27 22:23
comments: true
categories: TDD, ruby
---

Getting the full benefits of [TDD](http://en.wikipedia.org/wiki/Test-driven_development) requires fast-running specs. The feedback cycle is what makes the difference between a pleasurable "red-green-refactor" flow and an eternity of testing-tedium where the only reason you're *writing* tests is so you be *done* writing them. While TDD is lauded in the Rails community, many large Rails apps suffer from slow-running test suites.

I've been working with a Rails app that has a couple of bloated, callback-ridden models. Much of the test-suite uses FactoryGirl, and generating test objects for those big models and their associations can slow things down to a crawl. So when a new feature came along, I took the opportunity to write some fast unit-tests in a different style.

### Couch-Surfer
Imagine an app that logs the journeys of world-travellers (lots of them) as they couch-surf around the globe visiting homebody friends. Each traveller periodically sends a postcard to their next host to let them know how far off they are. We have a few persisted models: Traveller, Homebody, CouchCrash, and Postcard.

The Traveller and Homebody models are rather large, so I've abbreviated them here:

``` ruby
class Traveller < ActiveRecord::Base
  has_many :couch_crashes
  has_many :homebodies, through: :couch_crashes
  # and many more associations, validations, callbacks...
end

class Homebody < ActiveRecord::Base
  has_many :couch_crashes
  # and many more associations, validations, callbacks...
end
```

CouchCrash and Postcard are pretty small, despite their associations with the larger models:
``` ruby
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
end
```

Each visit, or `couch_crash`, is scheduled with an `arrival_date`. But these aren't always accurate, as it's hard to know exactly when the traveller will reach their destination. We'd like to add a feature that assesses the status of a visit as "far off", "approaching", or "in progress" based on the arrival date and available postcards. We won't bother with a "completed" status since couch-crashers have been known to stick around forever.

For simplicity's sake, we'll say any visit whose arrival date is more than a week away is "far off". Within a week of the arrival date, an "approaching" status requires a postcard from within 100 miles and "in Progress" requires one within 5 miles (I know, that's a waste of a stamp). Otherwise, with either no postcards or only those over 100 miles away, the visit remains "far off".

### Approaching the spec
A spec for the "approaching" status using FactoryGirl might look like this:

```ruby
describe CouchCrash do
  describe '#status' do

    context 'within 1 week of arrival date' do
      context 'with a postcard from 100 miles away' do

        it 'is "approaching"' do
          visit = FactoryGirl.build(:couch_crash, arrival_date: 1.week.from_now)
          postcard_100 = FactoryGirl.build(:postcard, distance: 100)

          visit.stub(:postcards).and_return([postcard_100])

          expect(visit.status).to eq(:approaching)
        end

      end
    end

  end
end
```

Using `build` rather than `create` should keep us from hitting the database. Stubbing the association between `visit` and its postcards should do the same. On the surface, this looks like a well-isolated, fast unit-test, but let's take a closer look at the factories we're using:

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

It's best practice to define your factories with the minimum set of attributes necessary for a valid object. You don't want to set land-mines for the next developer that comes along and calls `create`. So the couch_crashes factory generates associated traveller and homebody objects. In doing so, it involves two of our most bloated models. Take a look at their factories:

```ruby
# spec/factories/travellers.rb
FactoryGirl.define do
  factory :traveller do
    first_name "Yngwie"
    last_name  "Malmsteen"
    association :hometown, factory: :city
    luggage
    bicycle
    
    after(:build) do |traveller|
      pump = FactoryGirl.build(:bicycle_pump)
      traveller.bike_pump = pump
      traveller.inflate_tires
      traveller.pack_luggage
      traveller.buy_stamps
      # etc.
  end
end

# spec/factories/homebodies.rb
FactoryGirl.define do
  factory :homebody do
    first_name "Joe"
    last_name  "Stumps"
    spouse
    credit_score 400
    house
    couch
    car
    dog
    # etc.
  end
end
```

We're also unintentionally hitting the database, as FactoryGirl saves both traveller and homebody in order to build the association. You can avoid this by specifying a build-strategy for the association:

```ruby
factory :couch_crash do
  association :traveller, strategy: :build
  association :homebody,  strategy: :build
  ...
```

You'd also have to change the syntax in the associated factories:
```ruby
factory :traveller do
  ...
  association :luggage, strategy: :build
  association :bicycle, strategy: :build
  ...
end

factory :homebody do
  ...
  association :house, strategy: :build
  association :couch, strategy: :build
  association :car,   strategy: :build
  association :dog,   strategy: :build
  ...
end
```

It would be nice to avoid involving these large models any more than necessary, so let's rewrite the spec with a different technique. Instead of using factories to generate complex test objects, we'll use test doubles to stub out the context.

### Test-doubles
Rspec's `double` method returns a test-double -- a dummy object that stands in for a more complex object from your production code. The double can be told how to respond to various method calls:
```ruby
red_thing = double("thing")
# The argument (ie. "thing") is optional.
# It provides a name that test output can make use of.

red_thing.stub(:color).and_return("red")
# equivalent form:
red_thing.stub(:color) { "red" }

# Or, more concisely:
red_house = double("thing", color: "red")
```

The double only knows what it's been told explicitly, and will raise an error upon receiving any unexpected method call. If you're using Rspec 3, you can also use "[verifying doubles](https://www.relishapp.com/rspec/rspec-mocks/v/3-1/docs/verifying-doubles)", which know what class of object they're standing in for and will ensure that any methods being stubbed are actually present in the code.

### Rewrite
While our spec should still read from the ground up, beginning with the context and arriving at an expectation, it can be helpful when *writing* to start with the expectation and work backwards. This is especially true when the context is complex. It also helps clarify what needs to be stubbed out, so let's give it a shot.
```ruby
expect(visit.status).to eq(:approaching)
```
What is `visit`? Just a test double with the right attributes:
```ruby
visit = double("visit", arrival_date: 1.week.from_now, postcards: [postcard_100])
```
What about `postcard_100`? Just another test double.
```ruby
postcard_100 = double("postcard", distance: 100)
```
Putting it all together, we have:

```ruby
context 'within 1 week of arrival date' do
  context 'with a postcard from 100 miles away' do

    it 'is "approaching"' do
      postcard_100 = double("postcard", distance: 100)
      visit = double("visit", arrival_date: 1.week.from_now, postcards: [postcard_100])

      expect(visit.status).to eq(:approaching)
    end

  end
end
```

I initially wanted faster specs to enable a better TDD flow. A nice side benefit of writing these stubbed tests is that it illuminates the dependencies and coupling in the production code you're working with and encourages better composition overall. FactoryGirl is still a wonderful tool, but it shouldn't be the only one in your belt.
