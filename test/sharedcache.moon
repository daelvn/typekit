import DEBUG        from  require "typekit.config"
import inspect      from (require "typekit.debug") DEBUG
import Type, Record from  require "typekit.type.data"
import sign         from  require "typekit.sign"

Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"
import Nothing, Just from Maybe.constructor

va = Just 5
vb = Just true