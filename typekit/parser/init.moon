-- typekit.parser.init
-- Main parser module for typekit signatures
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG

-- Signature format
-- f :: Cl a => a -> b -> c
-- f :: {a:b} -> {b:a}
-- f :: [a] -> [b]
-- f :: Eq Ord a, Ord a => Maybe a -> Boolean

-- Returns and removes the name for a signature, if exists
nameFor = (sig) ->
  name = false
  sig  = sig\gsub "(.+)%s+::%s+", (n) ->
    name = n
    ""
  return name, sig

-- Returns the constraints in a signature
constraintsFor = ()