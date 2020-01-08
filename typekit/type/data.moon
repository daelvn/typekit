-- typekit.type.data
-- Datatypes for typekit
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import typeError    from  require "typekit.type.error"
import metatype     from  require "typekit.commons"

-- Type Synonym
--   Type "String", "[Char]"
Type = (A, T) -> -- A: Alias, T: Type
  (metatype "TypeSynonym") {
    alias: A
    type:  T
  }

-- Maybe = Data "Maybe a",
--   Just:    "a"
--   Nothing: ""

{
  :Type
}