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
--   data State s a = State { runState :: s -> (s, a) }
--       # Translates to #
--   Type "State s' a'",
--     State:    ""
--     runState: sign "s' -> Pair s' a'"
--       # Object structure #
--   State {s', a'}
--   runState :: s' -> Pair s' a'

import DEBUG          from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import addReference   from  require "typekit.global"
import typeError      from  require "typekit.type.error"
import sign           from  require "typekit.sign"
import curry,
       metatype,
       metakind,
       isLower,
       isUpper        from  require "typekit.commons"

-- Parses an annotation
-- Annotations are like "signatures" for types themselves
--   ex. "Either a b", "Maybe a"
parseAnnotation = (ann) -> [word for word in ann\gmatch "%S+"]

-- Builds a signature from a series of types
--   {String, Number, String} -> "String -> Number -> String"
buildSignature = (name, t) ->
  rest = table.concat t, " -> "
  "#{name} :: #{rest}"

-- Creates a new constructor
Constructor = (name, parent, __annotation) ->
  this            = {:__annotation, :parent, :name}
  this.annotation = parseAnnotation __annotation
  -- build signature
  ann             = [v for v in *this.annotation]
  table.insert ann, parent.name
  this.signature  = buildSignature this.name, ann
  Ct              = sign this.signature
  --
  return Ct curry ((...) ->
    log "Ct #got", inspect {...}
    return (metatype parent.name) (metakind this.name) {...}
  ), #this.annotation

-- Creates a new type
Type = (__annotation, definition) ->
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
  --
  this.constructor = {}
  for name, def in pairs definition
    if isLower name -- record
      Rf = sign
    elseif isUpper name -- constructor
      this.constructor[name] = Constructor name, this, def
      addReference name, this.constructor[name]
    else typeError "'#{name}' must begin with alphanumeric character"
  --
  return this

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