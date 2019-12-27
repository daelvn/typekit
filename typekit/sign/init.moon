-- typekit.sign.init
-- Signing functions for type checking
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import signError    from  require "typekit.sign.error"
import rebinarize   from  require "typekit.parser"

sign = (sig) -> setmetatable {
  signature: sig
  tree:      rebinarize sig
}, {
  __type: "SignedConstructor"
}

f = sign "f :: a -> b"