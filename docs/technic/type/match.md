# Technical specification for `typekit.type.match`

Everything to do with pattern matching.

## How are patterns matched against values?

typekit uses [tableshape][1] to recursively generate shapes that
match the expected value. It needs to introduce two types:
`Unbound` and `Variable`. `Unbound` is the type equivalent of
`_` in a for loop. It will match any type but not capture its
result. `Variable` takes an argument `String` used to capture the
value of the variable with that name.

Native types are matched literally, except for tables that are
matched using `Equivalent`, AKA deep compare. A special case,
`Pair`, is matched as a pair of any two values. Any other value is matched as `Partial [shapeFor x for x in *value]` if generated with
a constructor, and `Equivalent` otherwise.

## Variable injection

`match` returns the variables tagged in the comparison, and these
are the ones to be injected in the environment of the function to be
run.

[1]: https://github.com/leafo/tableshape