---
layout: post
title: "Polymorphic Mythology"
date: 2014-01-14 17:33
comments: true
categories: polymorphic associations
---
I was recently introduced to polymorphic associations in Active Record. They provide some extra flexibility in how you choose to wire up your models, and can be an elegant solution to some otherwise awkward problems. To demonstrate, I'll show how you could use them to catalog a collection of mythology.

We'll start with a tiny collection of tales: The Reign of the Hydra, The Golden Voyage, and The Life of King Adrastus. In addition to needing a myth model, we'll need models for beasts, voyages, and heros. Let's set things up so that a character/event/etc. can be the central figure in any number of myths, with each myth centered around a single such figure. Our beast model, then, could simply be,

```ruby
class Beast < ActiveRecord::Base
  has_many :myths
end
```

backed by a straightforward migration,

```ruby
class CreateBeasts < ActiveRecord::Migration
  def change
    create_table :beasts do |t|
      t.string :name
    end
  end
end
```

But wiring up the myth model isn't so simple. We could write three `belongs_to` statements into `myth.rb`, create three columns -- beast_id, voyage_id, and hero_id -- in the myths table, and find a way to enforce that two of the three always hold null values, but that's pretty cumbersome. Plus, as our catalog expands and we discover new types of central-figures (fools, floods, fires), we'll have to add more columns to accommodate any new classes we create. That's a lot of work to store a whole lot of nils.

Polymorphic associations allow you to handle this more elegantly. Let's describe the role that our central-figure plays in the context of a myth. For lack of a better term, I'll call it "memorable". A dragon ravishing the countryside, an epic voyage, a tragic hero, these are all "memorable" things that could take center-stage in a myth. Using this common thread, we'll build a polymorphic association that can relate a myth to any such "memorable" object.

```ruby
class Myth < ActiveRecord::Base
  belongs_to :memorable, :polymorphic => true
end
```

At the other end of the association, we'll tweak the `has_many` statements in each of our "memorable" models, declaring the role they can play in relation to a myth. The beast model, for example, becomes

```ruby
class Beast < ActiveRecord::Base
  has_many :myths, :as => :memorable
end
```

Now we can back the myth model with a much simpler table. The "memorable" central-figure's id and its type will be stored in a pair of columns, providing a myth with all it needs (a foreign key and the table that key applies to) to retrieve its central-figure.

```ruby
class CreateMyths < ActiveRecord::Migration
  def change
    create_table :myths do |t|
      t.string  :name

      t.integer :memorable_id
      t.string  :memorable_type
    end
  end
end
```

Active Record provides a shorthand for creating such a pair of columns: `t.references :memorable, :polymorphic => true`, which we could use in place of lines 6 and 7 above.

The polymorphic association allows us to create associations between existing objects,

```ruby
adrastus = Hero.create(:name => "Adrastus")
life = Myth.create(:name => "The Life of King Adrastus")
life.memorable = adrastus

afterlife = Myth.create(:name => "The Afterlife of King Adrastus")
adrastus.myths << afterlife
```

and to build associated myths off of a given "memorable" object,

```ruby
adrastus.myths.build(:name => "Adrastus - The Prequel")
adrastus.save

adrastus.myths.create(:name => "Adrastus IV - The Return")
```

Note, however, that we can't build a "memorable" object off of a given myth, since the type of object (hero, voyage, etc.) is ambiguous.
