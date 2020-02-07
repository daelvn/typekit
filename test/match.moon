import DEBUG        from  require "typekit.config"
import inspect, log,
       processor    from (require "typekit.debug") DEBUG
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
-- stat, err = match (case Nothing), 1, Just 5
-- print "aaaa", (inspect stat), (inspect err)
-- stat, err = match (case Just vx), 1, Just 5
-- print "aaaa", (inspect stat), (inspect err)

-- unwrap = sign "unwrap :: Maybe a -> a"
-- unwrap           (x)   -> x[1]
-- unwrap[case Nothing] = -> error "Cannot be Nothing"
-- unwrap[case Just vx] = => @x

-- print "-------------------"
-- j5 = Just 5
-- print "///////////////////"
-- print inspect unwrap j5

print "$1 ------------------------------------------"
fromMaybe = sign "fromMaybe :: a -> Maybe a -> a"
print "$2 ------------------------------------------"
fromMaybe[case _,  Just vx] = -> => @x
print "$3 ------------------------------------------"
fromMaybe[case vx, Nothing] = -> => @x
print "$4 ------------------------------------------"
j7 = Just 7
print "$5 ------------------------------------------"
f5 = fromMaybe 5
print "$6 ------------------------------------------"
v  = f5 j7
print "$7 ------------------------------------------"
print inspect v, processor.sign