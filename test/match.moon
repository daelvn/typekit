import DEBUG        from  require "typekit.config"
import inspect      from (require "typekit.debug") DEBUG
import Type, Record from  require "typekit.type.data"
import sign         from  require "typekit.sign"
import case,
       match,
       Variable,
       Unbound      from  require "typekit.type.match"

Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"

import Nothing, Just from Maybe.constructor

V, _ = Variable, Unbound
vx   = V"x"

fromMaybe = sign "a -> Maybe a -> a"
fromMaybe[case Just, vx] = (a) -> -> x
fromMaybe[case Nothing]  = (a) -> -> a

print fromMaybe Just 5