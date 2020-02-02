# Technical specification for `typekit.type.data`

Module responsible for datatype creation.

## What is a datatype?

This is absolutely not a valid explanation, only explains how they
work in typekit. I managed to do all of this without knowing
anything about type theory, somehow.

In here, a datatype is just a structure that defines constructors
that create more structures of the type defined in the datatype.
This does not mean anything.

```hs
data Maybe a = Nothing | Just a
```

Here, `Maybe` would be our datatype, and `Nothing` and `Just` our
two constructors that create structures of type `Maybe`. Internally,
each structure has a kind attached to identify the constructor
used to build the structure. This is how you can difference
`Nothing` from `Just`. But the user should only use pattern
matching for that.

This would be defined as such in typekit:

```moon
Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"
-- and only if typekit.config.GLOBAL == false
import Nothing, Just from Maybe.constructor
```

The `Type` function takes a string, called the annotation, which
defines the type name and the possible type variables. Defined as
`<name> [arg [arg...]]`. It also takes a string (creating a type
synonym) or a table `{String:String}`, where the key is the name of
the constructor and the value the annotation used to build the
constructor.

## Constructors

Constructors are functions which take the arguments defined in its
annotation and returns them wrapped in a table in order, with its
type set to the name of the type and the kind set to the name of the
constructor.

## Record syntax

Let's get a random Haskell example:

```hs
data Point = Point
  { pointX :: Number
  , pointY :: Number
  }
```

This would translate to:

```moon
Point = Type "Point",
  Point: { ""
    {pointX: "Number"}
    {pointY: "Number"}
  }
```

This generates two functions: `pointX` and `pointY`, with signature
`<name> :: Point -> Number`, which can be imported with
`import pointX, pointY from Point.constructor.Point.record` in case
that globals are not allowed in the config. They will return the
values automatically.

To call a function using record syntax, you will need to use
`typekit.type.data.Record` to call them, because I could not find a
better way. You can also just not use record syntax to call (and it
will still automatically generate the function).

```moon
import Point  from Point.constructor
import pointX from Point.record -- Point is Point.constructor.Point

pt = Point Record {
  pointX: 0
  pointY: 0
}
pointX pt -- 0
```