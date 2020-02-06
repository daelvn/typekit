-- typekit.type.init
-- Type checker function
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import typeError    from  require "typekit.type.error"
import metatype     from  require "typekit.commons"

-- save native type resolver under a different name
native = type

-- Map of native types to its typekit equivalents
BASE_TYPES = {
  string:   "String"
  number:   "Number"
  boolean:  "Boolean"
  function: "Function"
  table:    "Table"
  thread:   "Thread"
  userdata: "Userdata"
  nil:      "Nil"
}

-- Priorities
--   Resolvers allow a certain number of priorities to set your resolver.
--   - before-native : Puts the Resolver before the native type function (but after the meta resolver)
--   - after-meta    : Equivalent to before-native
--   - before-meta   : Puts the Resolver before the meta resolver function

-- Creates a new resolver with embedded data such as possible types
Resolver ==> setmetatable {
  name:     @name     or "?"
  resolve:  @resolve  or typeError "Resolver '#{@name}' lacks @resolve function."
  returns:  @returns  or {}
  priority: @priority or "before-meta"
}, {
  __type: "Resolver"
  __call: (...) => @.resolve ...
}

-- Native type resolver
type1 = Resolver {
  name:    "type1"
  resolve: (v) -> BASE_TYPES[native v]
  returns: [v for _, v in pairs BASE_TYPES]
}

-- Meta resolver
-- Checks for a __type metamethod/metavalue
hasMeta = Resolver {
  name:    "hasMeta"
  resolve: (v) ->
    local meta
    if type_mt = getmetatable v
      meta = type_mt.__type
    else return false
    switch native meta
      when "function" then meta v
      when "string"   then meta
      else                 false
  priority: "before-meta"
}

-- IO Resolver
isIO = Resolver {
  name:     "isIO"
  resolve:  (v) -> (io.type v) and "IO" or false
  returns:  {"IO"}
  priority: "after-meta"
}

-- The core function
typeof = setmetatable {
  -- type synonyms
  synonyms: {}
  -- datatypes
  datatypes: {}
  -- typeclasses
  typeclasses: {}

  -- resolver ordered list
  resolvers: {type1}
  -- index for @resolvers
  resolver_order: {[type1]: 1}
  -- associative resolver list
  -- matches types to resolvers
  resolver_map: {v, type1 for _, v in pairs BASE_TYPES}
  -- resolver names
  resolver_names: {[type1]: "type1"}

  -- Position of the meta resolver
  meta_pos: 1

  -- uses resolvers on value
  resolve: (v) =>
    log "type.typeof.resolve #got", "Resolving..."-- #{inspect v}"
    for resolver in *@resolvers
      if ty = resolver v
        log "type.typeof.resolve #resolved", "Resolved '#{ty}' by #{@resolver_names[resolver]}"
        return ty
    return false
      
}, {
  __type: "Function"
  __call: (...) => @resolve ...
}

-- Registers a resolver in typeof
register = (R) ->
  typeError "register requires a Resolver, got #{(hasMeta R) or native R}" if (hasMeta R) != "Resolver"
  -- set depending on priority
  -- 'native' is always resolvers[#resolvers]
  -- 'hasMeta' changes positions (is tracked)
  switch R.priority
    when "before-native"
      table.insert typeof.resolvers, (#typeof.resolvers - 1), R
    when "after-meta"
      table.insert typeof.resolvers, (typeof.meta_pos + 1), R
    when "before-meta"
      table.insert typeof.resolvers, 1, R
      typeof.meta_pos += 1
  -- make resolvers order
  typeof.resolver_order = {v, k for k, v in pairs typeof.resolvers}
  -- insert in resolver names
  typeof.resolver_names[R] = R.name
  -- insert in resolver map
  for t in *R.returns do typeof.resolver_map[t] = R

-- Register resolvers
register hasMeta
register isIO

-- Check the type of a list
-- [a]
typeofList = (l) ->
  is = typeof l[1]
  for v in *l
    t = typeof v
    if t != is then typeError "Type disagreement in List checked with typeofList. Got '#{t}', expected '#{is}'"
    is = t
  is

-- Check the type of a table
-- {a:b}
typeofTable = (t) ->
  start = true
  local isk, isv
  for k, v in pairs t
    if start
      start = false
      isk, isv = (typeof k), (typeof v)
    ttk, ttv = (typeof k), (typeof v)
    if ttk != isk then typeError "Type disagreement in key of Table checked with typeofTable. Got '#{ttk}', expected '#{isk}'"
    if ttk != isv then typeError "Type disagreement in value of Table checked with typeofTable. Got '#{ttv}', expected '#{isv}'"
    isk, isv = ttk, ttv
  isk, isv

-- Type synonyms
Type = (A, T) ->
  synonym = (metatype "TypeSynonym") {
    alias: A
    type:  T
  }
  typeof.synonyms[A] = synonym

-- Resolves a type synonym
resolveSynonym ==>
  log "type.resolveSynonym #got", inspect @
  -- Does not support table aliases since that would be too overkill.
  for _, synonym in pairs typeof.synonyms
    log "type.resolveSynonym #found", inspect synonym
    if "string" == type @
      return synonym.type if @ == synonym.alias
    elseif "table" == type @
      if @container and (@container == "Table")
        @key   = synonym.type if @key   == synonym.alias
        @value = synonym.type if @value == synonym.alias
      elseif @container and (@container == "List")
        @value = synonym.type if @value == synonym.alias
      elseif @data
        for i=1, #self do @[i] = synonym.type if @[i] == synonym.alias
  return @

-- Gets the kind of a value
kindof = Resolver {
  name:     "kindof"
  resolve:  (v) ->
    local meta
    if type_mt = getmetatable v
      meta = type_mt.__kind
    else return false
    switch native meta
      when "function" then meta v
      when "string"   then meta
      else                 false
  returns:  {}
  --priority: "after-meta" // not supposed to go in typeof
}

{
  :Resolver
  :type1, :hasMeta, :isIO
  :typeof, :kindof
  :register
  :typeofList, :typeofTable
  :Type, :resolveSynonym
}