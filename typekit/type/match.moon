-- typekit.type.match
-- Pattern matching for typekit
-- By daelvn
import DEBUG          from  require "typekit.config"
import inspect, log,
       processor      from (require "typekit.debug") DEBUG
import typeof, kindof from  require "typekit.type"
import typeError      from  require "typekit.type.error"
import metatype,
       parentOf       from  require "typekit.commons"

-- Notes
--   lucky :: Number -> String
--   lucky 7 = "Lucky number!"
--   lucky x = "Number is not lucky :("
--       # Traditional syntax #
--   lucky = sign "Number -> String"
--   lucky (x) -> match x,
--     [case 7]:   "Lucky number!"
--     [case x]: "Number is not lucky :("
--       # New syntax? #
--   lucky = sign "Number -> String"
--   lucky[ case 7   ] =     -> "Lucky number!"
--   lucky[ case "x" ] = (x) -> "Number #{x} is not lucky :("

Unbound  =        (metatype "Unbound")     {}
Variable = (s) -> (metatype "Variable")    {variable: s}
Offset   = (n) -> (metatype "TKTM_Offset") {:n}

-- Creates a case for pattern matching
-- Possible cases:
--   Lua value (native type)
--     Number, Boolean, Nil...
--   Constructor
--     Just, Right
--     Requires arguments (Variable, Unbound, native...)
--   Variable
--     V"x"
--   Unbound
--     _
case = (...) ->
  argl = {...}
  of   = 0
  if "TKTM_Offset" == typeof argl[1]
    of = argl[1].n
    table.remove argl, 1
  log "type.match.case #got", inspect argl, processor.match
  --
  this = (metatype "Case") {}
  --
  ct = 0
  for i, arg in ipairs argl
    this[of+i] = {}
    if ct != 0
      ct -= 1
      continue
    switch typeof arg
      when "String", "Number", "Table", "Thread", "Boolean", "Userdata", "Nil"
        -- lua native
        this[of+i].mode  = "match-eq"
        this[of+i].type  = typeof arg
        this[of+i].value = arg
      when "Function"
        log "type.match.case #fn", inspect kindof arg
        if "Constructor" == kindof arg
          -- constructor
          log "type.match.case #patlen", #arg.annotation
          this[of+i].mode    = "match-pat"
          this[of+i].const   = arg
          this[of+i].pattern = for ii=of+i+1, of+i+#arg.annotation do argl[ii]
          ct                 = #arg.annotation
          continue
        else
          -- lua native
          this[of+i].mode  = "match-eq"
          this[of+i].type  = typeof arg
          this[of+i].value = arg
      when "Variable"
        -- variable
        this[of+i].mode = "save-var"
        this[of+i].name = arg.variable
      when "Unbound"
        -- _
        this[of+i].mode = "skip"
      else
        -- some other type
        this[of+i].mode  = "match-eq"
        this[of+i].type  = typeof arg
        this[of+i].value = arg
  --
  return this

-- Match a value against a case
match = (i, val, C) ->
  cs   = C[i] or C[#C]
  log "type.match #got", inspect {:i, :val, :cs}, processor.match
  -- list of saved variables to be injected
  varl = {}
  --
  switch cs.mode
    when "skip"
      return true, varl
    when "save-var"
      varl[cs.name] = val
      return true, varl
    when "match-eq"
      -- Check for equality
      return (cs.value == val), varl
    when "match-pat"
      const  = cs.const
      expect = cs.const.parent.name
      log "type.match #compare", inspect {:expect, :val}, processor.match
      return false, varl if expect != typeof val
      -- check current part
      log "type.match #pattern", inspect cs.pattern
      cpart      = case Offset(i-1), cs.pattern[i]
      log "type.match #cpart", inspect {:i, :cpart}
      stat, varl = match i, val[i], cpart
      log "type.match #delegate", inspect {:stat, :varl}
      return stat, varl
    else typeError "Unknown case type #{cs.mode}"

{
  :case, :match
  :Variable, :Unbound
}