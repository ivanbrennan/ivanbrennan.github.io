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
  describe '#status' do

    context 'with a postcard from 100 miles away' do

      it 'is "approaching"' do
        visit = FactoryGirl.build(:couch_crash)
        postcard_100 = FactoryGirl.build(:postcard, distance: 100)

        visit.stub(:postcards).and_return([postcard_100])

        expect(visit.status).to eq(:approaching)
      end

    end

  end
end
```

Using `build` (rather than `create`) and stubbing the association between `visit` and its postcards should keep us from hitting the database. On the surface, this looks like a well-isolated (and fast, we'd hope) unit-test, but let's take a closer look at the factories we're using:

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

It's best practice to define your factories with the minimum set of attributes necessary for a valid object. You don't want to set land-mines for the next developer that comes along and calls `create`.

So the couch_crashes factory generates associated traveller and homebody objects. In doing so, it involves two of our most bloated models. Just look at their factories:

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

We're also unintentionally hitting the database, as FactoryGirl will save the traveller and the homebody in order to build the association. You can avoid this pitfall by changing the syntax a bit in the couch_crash factory:

```ruby
factory :couch_crash do
  association :traveller, strategy: :build
  association :homebody,  strategy: :build
  ...
```

Of course, you'd also have to change the syntax in the associated factories:
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

It would be nice to avoid involving these large models any more than necessary, so let's rewrite the spec with a different technique. Instead of using factories to generate complex test objects, we'll use test doubles to stub out the context without piling on irrelevant details.

Rspec's `double` method returns a test-double -- a dummy object that stands in for some more complex object from the production code. The double can be told how to respond to various method calls, allowing you to stub out the context of your test.
```ruby
red_thing = double("thing")
red_thing.stub(:color).and_return("red")
# equivalent form:
red_thing.stub(:color) { "red" }

# Or, more concisely:
red_house = double("thing", color: "red")
```
The `"thing"` argument above is optional. It just provides a name/description for the test output.

The double only knows what it's been explicitly told, and will raise an error if it receives an unexpected method call, but for unit-testing isolated code it's very useful. If you're using Rspec 3, you can also use "[verifying doubles](https://www.relishapp.com/rspec/rspec-mocks/v/3-1/docs/verifying-doubles)", which know what class of object they're standing in for and will ensure that any methods being stubbed are actually present in the code.

Getting back to our example, though the test should still *read* from context to expectation, when *writing*, I often find it helps to start with the expectation and work backwards. This is especially true when dealing with complicated contexts. It also helps clarify exactly what needs to be stubbed out, so let's give it a shot.
```ruby
expect(visit.status).to eq(:approaching)
```
What is `visit`? Just a test double with the right kind of postcard:
```ruby
visit = double("visit", postcards: [postcard_100])
```
What about `postcard_100`? Just another test double.
```ruby
postcard_100 = double("postcard", distance: 100)
```
Putting it all together, we have:

```ruby
context 'with a postcard from 100 miles away' do

  it 'is "approaching"' do
    postcard_100 = double("postcard", distance: 100)
    visit = double("visit", postcards: [postcard_100])

    expect(visit.status).to eq(:approaching)
  end

end
```

