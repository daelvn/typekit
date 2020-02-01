# Technical specification for `typekit.sign`

This is the module responsible for signing functions and all
underlying type checking, the very reason typekit exists.

## What is a type signature?

Type signature or type annotation is the name I give in typekit to
both the strings that define the types to be checked and the ASTs
representing these strings. This is what tells this module how
to typecheck.

## What is signing?

Signing is applying a type signature to a function. This works
by assigning `sign <signature>` to your future function, creating
a `SignedConstructor`, which can then be defined by calling
it with a function or by setting patterns by setting an index.

## How it works

### The `sign` function

This creates the `SignedConstructor`, parses the signature, and
handles the whole passing around arguments.

### `SignedConstructor`

They have a property `safe`, defaulting to `false`, that will error
on warnings if set to true. The use-case of this function is to
disable automatic signing of returned functions.

```moon
add = sign "Number -> Number -> Number"

-- this becomes invalid
-- add (x) -> (y) -> x + y

-- this is valid
-- but there is barely any point
add (x) -> sign"Number -> Number" (y) -> x + y
```

They also have a property `silent` which will suppress all warnings,
also defaulting to `false`.

They can be called with a function to set the function to be
typechecked (or fallback function), or indexed as a table to
assign patterns for pattern matching.

```moon

id = sign "a -> b"
id (x) -> x

id[ Case 5           ] = -> 4
id[ Case Variable "x"] = -> x
```

It returns a callable curried function via `wrap`.

### `wrap`

`wrap` essentially takes a function (`SignedConstructor` in reality)
and adds typechecking at both sides. The type checking is provided
by `checkSide`.

### `checkSide`

Compares the signature tree to the values passed, and reports errors
accordingly.