-- typekit.type.data
-- Datatypes for typekit
-- By daelvn

-- This is in fact the third implementation of this concept.
-- The others were overengineered and certainly too complex.

-- Notes:
--   data Maybe a = Nothing | Just a
--       # Translates to #
--   Type "Maybe a", -- this shows up in signatures
--     Nothing: ""
--     Just:    "a"
--       # Object structure #
--   Maybe {a} -- Just a
--   Maybe { } -- Nothing
--
--   data Person = Person {
--     name :: String
--     age  :: Int
--   }
--       # Translates to #
--   Type "Person",
--     Person:
--       ""
--       name: "String"
--       age:  "Int"
--       # Constructors #
--     Person :: String -> Int -> Person
--     name   :: Person -> Int
--     age    :: Person -> String
--       # Application #
--     Person "Dael" 16
--     Person R{ name: "Dael", age: 16 }
--
--   data State s a = State { runState :: s -> (s, a) }
--       # Translates to #
--   Type "State s' a'",
--     State:    ""
--     runState: "s' -> Pair s' a'"
--       # Object structure #
--   State {s', a'}
--   runState :: s' -> Pair s' a'

import DEBUG          from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import addReference   from  require "typekit.global"
import Type, typeof   from  require "typekit.type"
import typeError      from  require "typekit.type.error"
import sign           from  require "typekit.sign"
import curry,
       metatype,
       metakind,
       metaparent,
       getPair,
       isLower,
       isUpper        from  require "typekit.commons"
--unpack or= table.unpack

-- Parses an annotation
-- Annotations are like "signatures" for types themselves
--   ex. "Either a b", "Maybe a"
parseAnnotation = (ann) -> [word for word in ann\gmatch "%S+"]

-- Builds a signature from a series of types
--   {String, Number, String} -> "String -> Number -> String"
buildSignature = (name, t) -> "#{name} :: #{table.concat t, " -> "}"

-- Creates a new constructor
Constructor = (name, parent, definition) ->
  this = {:definition, :parent, :name, record: {}, rorder: {}}
  -- check if we have records
  if "Table" == typeof definition
    this.annotation = parseAnnotation definition[1]
    table.remove definition, 1
    for rec in *definition
      -- get record information & signature
      record, sig = getPair rec
      recf        = sign "#{record} :: #{parent.name} -> #{sig}"
      -- get position & add record
      lat                  = #this.annotation+1
      this.rorder[record]  = lat
      this.annotation[lat] = sig
      -- function & add reference
      -- FIXME reference is not added here
      parent.record[record] = recf (x) -> x[lat]
  else
    this.annotation = parseAnnotation definition
  -- validate variables
  for var in *this.annotation
    log "type.data.Constructor #var", var
    if (isLower var) and (not parent.variablel[var])
      typeError "No variable '#{var}' in type annotation"
  -- build signature
  ann = [v for v in *this.annotation]
  log "type.data.Constructor #ann", inspect ann
  -- @IMPL if we take no arguments, return object directly
  if #ann == 0
    log "type.data.Constructor #direct", "Direct constructor -> #{this.name}"
    return (metaparent parent) (metatype parent.name) (metakind this.name) setmetatable {}, __tostring: this.name 
  -- keep building signature
  table.insert ann, parent.name
  this.signature  = buildSignature this.name, ann
  Ct              = sign this.signature
  Ctf             = Ct curry ((...) ->
    log "Ct #got", inspect {...}
    return (metaparent parent) (metatype parent.name) (metakind this.name) setmetatable {...}, __tostring: this.name
  ), #this.annotation
  --
  return (metatype "Function") (metakind "Constructor") setmetatable this, __call: (x) => switch typeof x
    when "Record"
      argl = {}
      for record, val in pairs x
        log "type.data.Constructor #record", "Calling with record syntax, #{this.rorder[record]} is #{inspect val}"
        argl[this.rorder[record]] = val
      log "type.data.Constructor #record", "Arguments are #{inspect argl}"
      fn = Ctf
      for arg in *argl do fn = fn arg
      return fn
    else
      return Ctf x

-- Creates a new type
_TSyn = Type
Type  = (__annotation, definition) ->
  -- typechecking
  if "String" != typeof __annotation
    typeError "Expected String as argument #1 to Type"
  if "String" == typeof definition
    return _TSyn __annotation, definition
  elseif "Table" != typeof definition
    typeError "Expected Table/String as argument #2 to Type"
  --
  this = {:__annotation, :definition}
  -- validate name & typevars
  this.annotation = parseAnnotation __annotation
  unless isUpper this.annotation[1]
    typeError "Type name '#{this.annotation[1]}' must begin with uppercase"
  for i=2, #this.annotation do unless isLower this.annotation[i]
    typeError "Type variable '#{this.annotation[i]}' must begin with lowercase"
  this.name = this.annotation[1]
  -- expects
  this.expects = #this.annotation - 1
  -- variables
  this.variables = {i-1, this.annotation[i] for i=2, #this.annotation}
  this.variablel = {v, k for k, v in pairs this.variables}
  --
  this.constructor = {}
  this.record      = {}
  for name, def in pairs definition
    if isUpper name -- constructor
      this.constructor[name] = Constructor name, this, def
      addReference name, this.constructor[name]
    else typeError "'#{name}' must begin with uppercase character"
  --
  addReference this.name, this
  return (metatype "Type") (metakind this.name) setmetatable this, __tostring: this.name

-- Passing record syntax to constructors
Record = (t) -> (metatype "Record") t

{
  :Type, :Constructor, :Record
}