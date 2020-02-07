-- typekit.commons
-- Common functions across all modules
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
unpack or= table.unpack

-- Trims spaces around a string
trim = (str) ->
  if str == nil                   then return nil
  if x = str\match "^%s*(.-)%s*$" then x            else str

-- Checks if a table contains an element
contains = (t, elem) ->
  log "commons.contains #got", inspect {:t, :elem}
  for _, v in pairs t
    return true if elem == v
  return false 

-- check for types
isString = (v) -> "string" == (type v)
isTable  = (v) -> "table"  == (type v)

-- lowercase and uppercase detection
isUpper = (s) -> s\match "^%u"
isLower = (s) -> s\match "^%l"

-- Gets left and right for a signature
getlr = (sig) -> return sig.left, sig.right

-- Sets the metatype for a table
metatype = (T) -> (t) ->
  log "metatype", "setting to #{T}"
  if x = getmetatable t
    x.__type = T
  else
    setmetatable t, __type: T
  t

-- Sets the metakind for a table
-- Kinds are used for differencing constructors in types\
metakind = (K) -> (t) ->
  if x = getmetatable t
    x.__kind = K
  else
    setmetatable t, __kind: K
  t

-- Sets the parent of an object
metaparent = (P) -> (t) ->
  if x = getmetatable t
    x.__parent = P
  else
    setmetatable t, __parent: P
  t

-- returns the parent of an object
parentOf = (t) -> (getmetatable t).__parent

-- checks whether a table is empty
empty = (t) ->
  ct = 0
  for _, _ in pairs t do ct += 1
  ct == 0

-- Sets the __index metamethod for a table
-- Handles merging
metaindex = (__index) -> (t) ->
  if x = getmetatable t
    -- merge
    if __oldindex = x.__index
      -- only handle functions
      if "function" == type __oldindex
        -- nerge functions
        x.__index = (idx) =>
          if y = __index @, idx
            return y
          else
            return __oldindex @, idx
        return t
      -- merging tables not supported
      else return t
    -- no merge
    else
      x.__index = __index
      return t
  -- no metatable
  else return setmetatable t, :__index

-- get the amount of keys in a table
keysIn = (t) ->
  n = 0
  for _, _ in pairs t do n += 1
  return n

-- Checks that two tables share the same keys
containsAllKeys = (trg, base) ->
  for k, _ in pairs base do return false unless trg[k]
  return true

-- Flattens a table
flatten = (t) ->
  ret = {}
  for v in *t
    if "table" == type v
      for fv in *flatten v do table.insert ret, fv
    else table.insert ret, v
  return ret

-- Curries a function given the arity
curry = (fn, arity=2) ->
  -- Lua 5.2+
  -- arity or= (debug.getinfo fn, "u").nparams
  return fn if arity < 2
  helper = (at, n) -> return switch n < 1
    when true then fn unpack flatten at
    else           (...) -> helper {at, ...}, n - select "#", ...
  return helper {}, arity

-- Uncurries a function
uncurry = (fn) -> (...) ->
  argl = {...}
  fn   = fn
  for arg in *argl
    fn = fn arg
  fn

-- Binds an argument as the first one to a function
bind = (fn) -> (v) ->
  log "bind", "bound #{inspect v} to #{inspect fn}"
  (...) -> (fn v) ...

-- Gets the first key found in a table
getPair = (t) -> for k, v in pairs t do return k, v

-- clone
-- Shallow-clone a table
clone = (t) -> {k, v for k, v in pairs t}

-- setfenv
setfenv or= (fn, env) ->
  log "setfenv", "setting env for #{inspect fn}"
  oldf, isin = {}, false
  if ("table" == type fn) and
     (getmetatable fn)    and
     (getmetatable fn).__call
    oldf = fn
    fn   = (getmetatable fn).__call
    --fn   = (bind (getmetatable fn).__call) fn
    isin = true
  i = 1
  while true do
    name = debug.getupvalue fn, i
    if name == "_ENV"
      debug.upvaluejoin fn, i, (-> env), 1
    elseif not name
      break
    i += 1
  if isin
    (getmetatable oldf).__call = fn
    return oldf
  else
    return fn

{
  :trim, :isUpper, :isLower, :isString
  :contains, :isTable, :clone
  :getlr
  :metatype, :metaindex, :metakind, :metaparent
  :parentOf
  :empty, :keysIn, :containsAllKeys, :getPair
  :flatten, :curry, :uncurry, :bind
  :setfenv
}