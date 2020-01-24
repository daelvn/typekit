-- typekit.type.match
-- Pattern matching for typekit
-- By daelvn
import DEBUG          from  require "typekit.config"
import inspect, log,
       processor      from (require "typekit.debug") DEBUG
import typeof, kindof from  require "typekit.type"
import typeError      from  require "typekit.type.error"
import metatype,
       isUpper,
       isLower        from  require "typekit.commons"  

Unbound  =        (metatype "Unbound")     {}
Variable = (s) -> (metatype "Variable")    {variable: s}

_, V = Unbound, Variable

-- Function that takes in any value and defines it as a shape.
import Tag, S, T, L, X from require "typekit.tableshape"
shapeFor = (x) -> switch typeof x
  when "Unbound"  then return T"any"
  when "Variable" then return (Tag T"any") x.variable
  when "String", "Number", "Thread", "Boolean", "Userdata", "Nil"
    return (Tag L x) "value"
  when "Table"
    return (Tag E x) "value"
  when "Pair"
    a, b = x[1], x[2]
    return (S {(shapeFor a), (shapeFor b)})
  else
    if kindof x then return S [shapeFor v for v in *x]
    else             return E x

-- Takes a list of things to match and returns a shape
-- case V"x", (Just V"y"), _
case = (...) ->
  shapel = {}
  for arg in *{...}
    table.insert shapel, shapeFor arg
  return (metatype "Case") shapel

-- Matches a value to part of a case
match = (C, i, v) -> C[i] v

{
  :case, :match
}