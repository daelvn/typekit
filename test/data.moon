import DEBUG        from  require "typekit.config"
import inspect      from (require "typekit.debug") DEBUG
import Type, Record from  require "typekit.type.data"
import sign         from  require "typekit.sign"

R = Record

Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"

Either = Type "Either l r",
  Left:  "l"
  Right: "r"

Person = Type "Person",
  Person: {
    ""
    {name: "String"}
    {age:  "Number"}
  }

import Nothing, Just from Maybe.constructor

j5     = Just 5
unwrap = sign "Maybe Number -> Number"
unwrap (mn) -> mn[1]

import name, age from Person.record
import Person    from Person.constructor

dael = (Person "Dael") 16
--print "MOTX", name dael

print "MOTX", inspect Nothing