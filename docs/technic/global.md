# Technical specification for `typekit.global`

This function is responsible for environment manipulation,
Stubs, Subfunctions and things related to injecting functions.

## Initialization

This module depends on the configuration variable
`typekit.config.GLOBALS`, that must be set to `true`.

The environment must be initialized with `initG!` to make sure that
the `_T` global table for typekit exists. This will also make
`_G` look for indexes in `_T`, therefore enabling things such as:

```moon
Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"

j5 = Just 5 -- this is put into _T
```

## Subfunctions

A subfunction is a named structure that contains a selector
function and a reference to a function. The selector function
determines whether this is the right subfunction to call, and
must return any truthy value. You can add a subfunction to a stub
with `addSubfn :: Stub -> Subfunction -> Nil`.

## Stubs

A stub is a structure found in `_T` that groups subfunctions and calls them accordingly. A stub can be added to `_T` with
`addStub :: Stub -> Nil`.