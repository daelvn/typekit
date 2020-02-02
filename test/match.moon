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

-- print inspect match (case Just Just V"x"), 1, Just Just 5

unwrap = sign "Maybe a -> a"
unwrap[case Nothing] = -> error "Cannot be Nothing"
unwrap[case Just vx] = -> x
unwrap           (x)   -> x[1]

print unwrap Just 5

--fromMaybe = sign "a -> Maybe a -> a"
--fromMaybe[case _,  Just vx] = -> -> x
--fromMaybe[case vx, Nothing] = -> -> x

--print fromMaybe Just 5