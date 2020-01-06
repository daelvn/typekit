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
    setmetatable x, __type: T
  t

-- checks whether a table is empty
empty = (t) ->
  ct = 0
  for k, v in pairs t do ct += 1
  ct == 0

{
  :trim, :isUpper, :isLower, :isString
  :contains, :isTable
  :getlr
  :metatype
  :empty
}