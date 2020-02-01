# Technical specification for `typekit.type.init`

This module contains the well-known and typical `typeof` function
from ltypekit1.

## Native types

These are `String`, `Number`, `Boolean`, `Function`, `Table`,
`Thread`, `Userdata` and `Nil`. They are all hardcoded in a hashmap
where the values are the native types and the keys are the types
reported by Lua's native `type` function.

## Resolvers

A resolver, made with constructor `Resolver :: Table -> Resolver`
is a named structure that usually contains a list of the types it
can possibly return, a priority to be inserted into `typeof`,
and a `resolve` function that takes in any value and returns a
string with its type, or false if it does not resolve. A resolver
can also be called as a function and is equivalent to calling
`myResolver.resolve`.

It is important to understand the precedence of resolvers to avoid
type mismatches. There are two resolvers that are tracked by
`typeof`:

### `type1`

Resolver that returns the Native Types.

### `hasMeta`

Resolver that returns whatever is found in `obj.<METATABLE>.__type`,
if found. If it is a function instead of a string, it will be called
with the value `obj` and is expected to return a string.

### Precedence

A resolver can have three precedences:

#### `"before-native"`

Puts the Resolver before the native type function (but after the
meta resolver). This means that your value certainly does not
have a `__type` metavalue but you do not want it to be identified
as a native type.

#### `"after-meta"`

Equivalent to `before-native`, but practically put right after
`hasMeta`, so a resolver with this precedence would be tried before
one with `before-native` precedence.

#### `before-meta`

Generally not recommended. Identifies types before trying to get
it's `__type` metavalue.

### Other important resolvers

##### `isIO`

Resolver as a wrapper to `io.type`. Returns the type `IO`.

### Creating your own types

Generally you will only need to use `__type`, but in case you want
a very specific structure such as vectors, you can always make a
custom checker for this.

```
isVector = Resolver {
  name:     "isVector"
  resolve:  (v) -> ("table"  == native v) and
                   ("number" == v.x     ) and
                   ("number" == v.y     ) and
                   ("number" == v.z     ) and "Vector"
  returns:  {"Vector"}
  priority: "before-meta"
}
```

Although in this example, you may also benefit from
`typekit.tableshape`:

```
import T, S, Tag from require "typekit.tableshape"

vector_S = S {
  x: Tag (T "number") "x"
  y: Tag (T "number") "y"
  z: Tag (T "number") "z"
}

isVector = Resolver {
  name:     "isVector"
  resolve:  (v) -> (vector_S v) and "Vector" or false
  returns:  {"Vector"}
  priority: "before-meta"
}
```

To register a resolver, use `registed :: Resolver -> Nil`

### `typeof`

This is the magical function, which has too much stuff to be
documented here. Not because I'm lazy, but because it's plainly
unnecessary.

It used to be a function in ltypekit1, then turned into a callable
table, and that resulted in a big benefit since now resolvers
are shared since tables are passed by reference.

All you need to know is that you can call `typeof` with
a single value, and it will try all resolvers on the value until
it comes up with one that works.

### `Type`

Although it takes a much more complex form in `typekit.type.data`,
in here it is only used to specify type synonyms. This makes
it so you can define:

```moon
Type "Int", "Number"
```

And it will work as a valid type synonym even in lists and
applications. Mind that `sign` only does a single pass to resolve
synonyms, so please avoid stuff like nested type synonyms or
recursive type synonyms.