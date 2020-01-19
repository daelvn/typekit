# TODO - Pattern Matching

Define `fromMaybe` as:

```hs
fromMaybe :: a -> Maybe a -> a
fromMaybe _ (Just b) = b
fromMaybe a Nothing  = a
```

Instead of flattening the function and then pattern-matching,
let's try to match patterns as we descend. That is, passing it
through sign somehow (for patterned subsigning).

```moon
fromMaybe :: a -> Maybe a -> a
fromMaybe[case V"x", Nothing] = -> (-> x)

fromMaybe'1 :: Maybe a -> a
fromMaybe'1[case Nothing] = -> x
```

Perhaps we can achieve this by signing the function, then applying
all patterns with the first argument removed, where the first
argument has already matched. So in `fromMaybe Just 5`, we would
apply all patterns at first because anything matches `_` and `x`,
but then insert them as `(Just x)` and `Nothing` instead of
`_ (Just x)` and `x Nothing`.

Also perhaps converting strings to cases such as:

```moon
fromMaybe["_ (Just x)"] = -> -> x
fromMaybe["x Nothing"]  = -> -> x
```

But these could be difficult to parse?