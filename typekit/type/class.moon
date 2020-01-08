-- typekit.type.class
-- Typeclasses for typekit
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import contains     from  require "typekit.commons"

-- Lookup table for instances and types
-- typeclass: creates [class]: {}
-- instance: inserts type into [class]
memberl = {
  -- Monad: {"Maybe"}
}

-- Returns the classes that a type is member of
classesFor = (T) ->
  cll = {}
  for cl, members in pairs memberl
    table.insert cll, cl if contains members, T
  --
  cll

{
  :classesFor
}