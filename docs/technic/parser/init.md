# Technical specification for `typekit.parser.init`

This module is responsible for signature parsing and creating
signature syntax trees.

## Syntax of signatures

```
name :: Cl a => a -> b -> c
name :: {a:b} -> {b:a}
name :: [a] -> [b]
name :: Eq a, Ord a => Maybe a -> Boolean
```

Basically supports constraints through `=>`, functions through `->`
which associate as you would expect, table structures `{a:b}` and
lists `[a]`. Also supports applications `m a` amongst others. It
supports naming by prefixing the signature with `(.+)::`.

## Binarize and Rebinarize

`binarize`, named as traditional from ltypekit1, splits a signture
into left and right side, optionally extracting a name and
constraints. It also does basic transformations such as `f :: a` ->
`f :: _ -> a`. The left and right side is determined by finding the
top-level (not contained in parenthesis or scoped) thin arrow
(`->`).

`rebinarize` essentially makes this a recursive process by finding
thin arrows in both sides (meaning that it can be further recursed
down). It also applies transformations such as creating application
structures, as well as table and list structures.