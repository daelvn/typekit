-- typekit.type.data
-- Datatypes for typekit
-- By daelvn
import DEBUG, GLOBALS from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import Type           from  require "typekit.type"
import typeError      from  require "typekit.type.error"
import metatype,
       isUpper,
       isLower        from  require "typekit.commons"

-- Parses an annotation
-- Annotations are like "signatures" for types themselves
--   ex. "Either a b", "Maybe a"
parseAnnotation = (ann) -> [word for word in ann\gmatch "%S+"]

-- Registers a constructor
registerConstructor = (C) ->
  (_ENV or _G)[C.name] = C if GLOBALS

-- Creates a type constructor
--   Examples of constructor strings.
--     "String"          : Requires a single string.
--     "String String"   : Requires two strings.
--     "a"               : Takes any parameter.
--     "a b"             : Takes any two parameters.
--     "name:String x:a" : Record syntax.
Constructor = (T, name, ann) ->
  -- constructor
  this = {}
  ctdef = parseAnnotation ann
  -- check name
  unless isUpper name
    typeError "Constructor name '#{name}' should be uppercase"
  this.name = name
  -- get __expects for constructor
  this.__expects = 0
  for i=2, #ctdef
    unless isLower ctdef[i]
      typeError "Variables to constructor must be in lowercase"
    this.__expects += 1
  -- return constructor
  return (metatype "Constructor") setmetatable this, __call: (...) ->
    argl = {...}
    if #argl != this.__expects
      typeError "Type expects #{this.__expects} arguments, got #{#argl}"
    --
    return (metatype T.name) {
      __built: this.name
      -- ...
    }

-- Type definition including type synonyms
_TypeSyn = Type
Type = (T, def) ->
  this = { order: {} }
  --
  if "string" != type T
    typeError "Expected string as argument #1 to Type"
  return _TypeSyn T, def if "string" == type def
  -- make type  
  if "table" == type def
    -- get parts
    tdef = parseAnnotation T
    -- get name
    unless isUpper tdef[1]
      typeError "Name of type must be in uppercase"
    this.name = tdef[1]
    -- get __expects
    this.__expects = 0
    for i=2, #tdef do this.__expects += 1
    -- insert parts
    for i=2, #tdef
      part = tdef[i]
      if {record, t} = part\match ":"
        this.order[record] = t
      else
        this.order[i] = t
    -- iterate thru constructors
    this.constructors = {}
    for cname, C in pairs def
      const                    = Constructor C
      this.constructors[cname] = const
      registerConstructor const
    -- return
    return this

-- Maybe = Data "Maybe a",
--   Just:    "a"
--   Nothing: ""

-- Identity = Newtype "Identity a", Id: "a"

-- Newtype == Data ?

{
  :Constructor, :Type
}