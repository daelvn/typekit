-- typekit.global
-- _G handling
-- By daelvn
import DEBUG, GLOBALS from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import stubError      from  require "typekit.global.error"
import metatype,
       metaindex,
       isUpper,
       isLower        from  require "typekit.commons"

-- Gets the current Lua version
--getVersion = (ver=_VERSION) -> ver\match "%d%.%d"

-- Initializes the global environment
initG = ->
  return if _G._T
  log "global.initG", "Initializing _T"
  if GLOBALS
    _G._T = {}
    _G    = (metaindex (i) => (rawget @, "_T")[i]) _G

-- Creates a new Subfunction
-- A Subfunction is a function that can be selected based
-- on some criteria, determined by a second function.
Subfunction = (name, fn, selector) ->
  log "global.Subfunction #got", name
  this = (metatype "Subfunction") {
    :name
    reference: fn
    :selector
  }
  setmetatable this, __call: (...) => @.reference ...

-- Creates a new stub
--   name:   name of the reference
--   subfnl: table of Subfunctions
Stub = (name, subfnl={}) ->
  log "global.Stub #got", name
  this = setmetatable { :name, :subfnl },
    __index: (idx) =>
      if x = (rawget @, "subfnl")[idx]
        return x
      else
        stubError "No Subfunction found with index '#{idx}'"
    __call:  (...) =>
      for name, subfn in pairs subfnl
        return subfn ... if subfn.selector ...
      stubError "No Subfunction could be inferred"
  --
  return this

-- Adds stub to _G
addStub = (stub) ->
  initG!
  _T[stub.name] = stub if GLOBALS

-- Adds subfunction to stub
addSubfn = (stub) -> (subfn) -> (rawget stub, "instances")[subfn.name] = subfn

-- Adds simple function as a reference
addReference = (name, fn) ->
  log "global.addReference #got", "Adding reference #{name}"
  initG!
  _G._T[name] = fn if GLOBALS

{
  :initG
  :Subfunction, :Stub
  :addSubfn,    :addStub
  :addReference
}