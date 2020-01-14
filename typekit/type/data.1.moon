-- typekit.type.data
-- Datatypes for typekit
-- By daelvn
import DEBUG, GLOBALS from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import compareSide    from  require "typekit.parser.compare"
import Type, typeof   from  require "typekit.type"
import typeError      from  require "typekit.type.error"
import Stub,
       Subfunction,
       addStub,
       addReference,
       addSubfn       from  require "typekit.global"
import metatype,
       metakind,
       metaindex,
       keysIn,
       containsAllKeys,
       isUpper,
       isLower        from  require "typekit.commons"

-- Parses an annotation
-- Annotations are like "signatures" for types themselves
--   ex. "Either a b", "Maybe a"
parseAnnotation = (ann) -> [word for word in ann\gmatch "%S+"]

-- Gets known records
getRecords = (ctdef) ->
  records = {}
  for part in *ctdef
    rec, t = {part\match "(.+):(.+)"}
    if rec and t
      records[x[1]] = x[2]
  return records

-- Generates holders for a type
--   "State s a" -> "a b"
--   "Maybe a"   -> "a"
holdersFor = (expects) ->
  total = {}
  for i=1, expects
    total[i] = string.char i+64
  table.concat total, " "

-- Side
sd = (x, y={constl:{}}) -> {right: x, constl: y.constl}

-- A Vessel generates a type for any constructor
Vessel = (T, C) -> (...) ->
  log "type.data.Vessel #got", "Generating vessel for #{T.name}/#{C.name}"
  argl  = {...}
  record = false
  -- record syntax?
  if (#argl          != C.__expects     ) and
     (#argl          == 1               ) and
     ("Table"        == typeof argl[1]  ) and
    --(keysIn argl[1] == keysIn C.records) and
     (containsAllKeys argl[1], C.records)
    record = true
  --
  this = {}
  local t
  -- use record syntax?
  if record then t = argl[1] else t = argl
  --
  for k, v in pairs argl[1]
    local expect
    if "Number" == typeof k
      expect = C.definition[k]
    elseif "String" == typeof k
      expect = C.records[k]
    else typeError "#{C.name} $ unknown key type #{typeof k}"
    --
    cache = {}
    status, err, cache = compareSide (sd expect), (sd typeof v), cache, "right"
    unless status
      typeError "#{C.name} ##{k} $ expected #{expect}, got #{typeof v}", {
        ((err.left or err.right) and "---" or nil)
        (err.left  and "Left:  #{err.left}"  or nil)
        (err.right and "Right: #{err.right}" or nil)
      }
    this[k] = v
  return (metatype T.name) (metatype C.name) this

-- Makes a constructor
Constructor = (T, name, ann) ->
  log "type.data.Constructor #got", inspect { :T, :name, :ann }
  -- constructor
  this  = {}
  ctdef = parseAnnotation ann
  -- get name
  unless isUpper name
    typeError "Constructor name '#{name}' for type '#{T.name}' must be uppercase"
  this.name = name
  -- get __expects for constructor
  this.__expects = #ctdef
  -- get and define records
  this.records   = getRecords ctdef
  if GLOBALS and ((keysIn this.records) > 0)
    for record, TT in pairs this.records
      -- create function for record
      -- first generate holders
      holders = holdersFor T.__expects
      -- now add the reference
      addReference record,
        (sign "#{record} :: #{T.name} #{holders} -> #{TT}") (=> @[record])
  -- set definition
  this.definition = ctdef
  -- create vessel
  __this = __call: Vessel T, this
  return (metatype "Function") setmetatable this, __this

-- Type definition including type synonyms
--   Type "String", "[Char]"
--
--   Type "Maybe a",
--     Just:    "a"
--     Nothing: ""
--
--   Type "Fd", Fd: "ci:CInt"
--
--   Type "State s a",
--     State:    ""
--     runState: sign "s' -> Pair s' a'"
_TSyn = Type
Type  = (T, def) ->
  this = { }
  --
  if "String" != typeof T
    typeError "Expected String as argument #1 to Type"
  return _TSyn T, def if "String" == typeof def
  if "Table" != typeof def
    typeError "Expected Table/String as argument #2 to Type"
  -- get parts
  tdef = parseAnnotation T
  -- get name and __expects
  unless isUpper tdef[1]
    typeError "Name of type '#{tdef[1]}' must be uppercase"
  this.name      = tdef[1]
  this.__expects = #tdef - 1
  -- create constructors
  this.constructor = {}
  (metaindex this.constructor) this
  for cname, c in pairs def
    -- generate constructor
    C = Constructor this, cname, c
    -- add to constructor list
    this.constructor[cname] = C
    -- if globals enabled, add reference
    addReference cname, C if GLOBALS
  -- return type
  return (metatype "Type") (metakind this.name) this

Maybe = Type "Maybe a",
  Just:    "a"
  Nothing: ""

print inspect Maybe
print inspect Maybe.Just 5