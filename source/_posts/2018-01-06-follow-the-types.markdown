---
layout: post
title: "follow the types"
date: 2018-01-06 13:18
comments: true
categories: Haskell
---

Time for some Haskell. The following expression evaluates to `Just 6`:
```haskell
fmap sum $ Just [1, 2, 3]
```

So does this one:
```haskell
(fmap . fmap) sum Just $ [1, 2, 3]
```

How does the second one work? How do the type signatures line up?

First consider `fmap . fmap`:
```haskell
(.) :: (b -> c) -> (a -> b) -> a -> c

fmap :: Functor f => (a -> b) -> (f a -> f b)

(.) fmap :: Functor f => (a1 -> (a -> b))
                      -> a1
                      -> (f a -> f b)

fmap . fmap :: (Functor f, Functor f1) => (a -> b)
                                       -> f1 (f a)
                                       -> f1 (f b)
```

Then `sum`:
```haskell
sum :: (Num a, Foldable t) => t a -> a
```

Now apply `fmap . fmap` to `sum`:
```haskell
(fmap . fmap) sum :: (Num b,
                      Foldable t,
                      Functor f,
                      Functor f1) => f1 (f (t b))
                                  -> f1 (f b)
```

Next, the tricky bit.
Note that `(a -> b) ~ ((->) a b)`.
So the signature of `Just`, which we'd usually write:
```haskell
Just :: a -> Maybe a
```
can also be expressed as:
```haskell
Just :: (->) a (Maybe a)
```

We want the type signature for `(fmap . fmap) sum Just`.

Consider the signature of `(fmap . fmap) sum`.
```
...
Functor f,
Functor f1) => f1 (f (t b))
            -> f1 (f b)
```

`f1` must have a Functor instance.

`((->) a)` has a [Functor instance](https://github.com/ghc/packages-base/blob/52c0b09036c36f1ed928663abb2f295fd36a88bb/GHC/Base.lhs#L234) for all a.

`((->) (t b))`, therefore, has a Functor instance.

If we replace `f1` with `((->) (t b))`, we produce a more specific type signature, expressing a specialization of `(fmap . fmap) sum`
```
        ... => ((->) (t b)) (f (t b))
            -> ((->) (t b)) (f b)
```

We can further specialize it by replacing `f` with Maybe.
```
        ... => ((->) (t b)) (Maybe (t b))
            -> ((->) (t b)) (Maybe b)
```

Now consider a specialization of `Just` where `a ~ (t b)`
```
Just :: (->) (t b) (Maybe (t b))
```

If we apply the specialized `(fmap . fmap) sum` to this specialization of `Just`, we get:
```
        ... => ((->) (t b)) (Maybe b)
```
which can be rewritten idiomatically as:
```
        ... => t b -> Maybe b
```

This leaves us with:
```haskell
(fmap . fmap) sum Just :: (Num b, Foldable t) => t b -> Maybe b
```
