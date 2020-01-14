import DEBUG   from  require "typekit.config"
import inspect from (require "typekit.debug") DEBUG
import Type    from require "typekit.type.data"
import sign    from require "typekit.sign"

Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"

j5     = Maybe.constructor.Just true
unwrap = sign "Maybe Number -> Number"
unwrap (mn) -> mn[1]

print inspect j5
print "==="
print "==="
print inspect unwrap j5