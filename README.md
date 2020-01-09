# type-synonyms/complex

The purpose of this branch is to implement type synonyms from `typekit.type.init` instead of `typekit.parser.transformer`, and to make type synonyms resolved at runtime.

## How?

If `this` (`@tree[side]`) holds the side being checked, this contains an element that can be type-replaced. The idea is to form a type-synonym and parse it using `selr` (see `master` branch), then match it, and if it matches, replace by the type-synonym (`ts.type`).

`typekit.type.init` will declare `Type` (type: `TypeSynonym`) instead of `typekit.type.data`, and will keep a record inside of `typeof` with the registered type-synonyms. Then `typekit.type.init` will provide a function that takes `this`, compares it to `ts.alias` and returns either `this` if failure or `ts.type` if success.