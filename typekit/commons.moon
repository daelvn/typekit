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

{
  :trim, :isUpper, :isLower, :isString
  :contains, :isTable
  :getlr
}