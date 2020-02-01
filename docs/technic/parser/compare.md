# Technical specification for `typekit.parser.compare`

This module is responsible for the comparison of signatures,
base and expected, to make sure that they are compatible.
The only original instance this was used was accepting functions
such as in `(a -> b) -> [a] -> [b]`, but its lesser function
`compareSide` is used throughout the whole project to compare any
two signature parts.

## Comparing process

`compare` is just a wrapper function for `compareSide`, which
checks that both sides compare correctly.

`compareSide` is recursive and fairly trivial. If the nodes being
compared are not compatible (list vs subsignature), false is
returned up. If the nodes being compared are both signatures,
return the results of its comparison. For other datatypes,
compare appropriately and return result.

## What compares and what does not

This is not always clear, but should be fairly intuitive:

### Compares

- Signature and signature
- Application and application
- Container and container(1)
- Container and Lua Native Table(2)
- Any and type variable
- Type and type
- Type variable and type variable

1: When comparing lists against lists, the value type must match. When comparing lists and tables, the key of the table is expected to be a number. When comparing tables against tables, both value and key types must match.

2: Always returns true.

The difference between types and type variables is in whether the first character is uppercase (type) or lowercase (type variable). In all cases constraints must be matched.

### Does not compare

- Signature and non-signature
- Application and non-application
- Container and signature