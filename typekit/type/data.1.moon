-- typekit.type.data
-- Datatypes for typekit
-- By daelvn
import DEBUG, GLOBALS from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import Type, typeof   from  require "typekit.type"
import typeError      from  require "typekit.type.error"
import metatype,
       isUpper,
       isLower        from  require "typekit.commons"

-- Parses an annotation
-- Annotations are like "signatures" for types themselves
--   ex. "Either a b", "Maybe a"
parseAnnotation = (ann) -> [word for word in ann\gmatch "%S+"]

-- Type definition including type synonyms
--   Type "String", "[Char]"
--
--   Type "Maybe a",
--     Just:    "a"
--     Nothing: ""
--
--   Type "Fd a", Fd: "CInt"
--
--   Type "State s a",
--     State:    ""
--     runState: sign "s' -> Pair s' a'"
_TSyn = Type
Type  = (T, def) ->
  this = { order: {} }
  --
  if "String" != typeof T
    typeError "Expected String as argument #1 to Type"
  return _TSyn T, def if "String" == typeof def
  if "Table" != typeof def
    typeError "Expected Table/String as argument #2 to Type"
  -- get parts
  tdef = parseAnnotation T
  -- get name and __expects
  unless isUpper tdef[1]
    typeError "Name of type '#{tdef[1]}' must be uppercase"
  this.name      = tdef[1]
  this.__expects = #tdef - 1
  -- 