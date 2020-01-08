-- typekit.parser.transformer
-- Applies changes to a signature tree
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import rebinarize   from  require "typekit.parser"

-- Transformation list
transformer = {}

-- Applies transformations to a tree
apply = (fnl) -> (node) ->
  -- apply transformations
  for _, fn in pairs fnl do node = fn node
  -- iterate
  for k, elem in pairs node
    if (type elem) == "table"
      node[k] = (apply fnl) elem
  -- return node
  return node

-- Runs a standalone version of apply with only a single
-- transformer
applyOne = (tr) -> (node) -> (apply {tr}) node

-- Parses a single type instead of a whole signature
selr = (T) -> (rebinarize T).right if "string" == type T else T

-- Applies a type synonym to a tree
-- (Transformer)
transformer.typeSynonyms = (ts) -> =>
  return @ if "table" != type @
  ts.type = selr ts.type
  if @left and ("string" == type @left)
    @left = ts.type if @left == ts.alias
  if @right and ("string" == type @right)
    @right = ts.type if @right == ts.alias
  if @data
    for i=1, #self do @[i] = ts.type if @[i] == ts.alias
  if @container
    @value = ts.type if @value == ts.alias
  if @container and (@container == "Table")
    @key = ts.type if @key == ts.alias
  return @

ts  = {alias: "String", type: "[Char]"}
me  = {alias: "Maybe",  type: "Either"}
int = {alias: "Int",    type: "Number"}

S = rebinarize "a -> String -> {Int:Int} -> Maybe e"
S = (applyOne transformer.typeSynonyms ts)  S
S = (applyOne transformer.typeSynonyms me)  S
S = (applyOne transformer.typeSynonyms int) S
log "ttetet", inspect S

{
  :transformer, :apply, :applyOne
}