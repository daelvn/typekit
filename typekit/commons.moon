-- typekit.commons
-- Common functions across all modules
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG

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

{
  :trim, :isUpper, :isLower, :isString
  :contains, :isTable
  :getlr
  :metatype, :metaindex, :metakind
  :empty, :keysIn, :containsAllKeys
}