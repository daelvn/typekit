-- typekit.parser.init
-- Parser for typekit signatures written in re
-- By daelvn
import parserError  from  require "typekit.parser.error"
re                     =  require "re"

shorthand = (s) ->
  s = s\gsub "$(%S+)", [[{:tag: "" -> "%1" :}]]
  return s

grammar = re.compile shorthand [[
  -- signature parser
  signature   <- ws {| $root name? constraints? function |}
  name        <- ws {:name: id :} ws "::" ws
  constraints <- ws {| $constraints typelist |} ws "=>" ws

  group       <- ws "(" ws (function / complex) ws ")"
  function    <- ws {| $fn {:left: gc :} ws "->" ws {:right: (group / function / complex) :} |}
  complex     <- tuple / table / list / type

  tuple       <- ws "(" {| $tuple gclist        |} ")"
  table       <- ws "{" {| $table type ":" type |} "}"
  list        <- ws "[" {| $list  type          |} "]"

  gclist      <- gc ("," ws gc)*
  gc          <- group / complex
  typelist    <- type ("," ws type)*
  type        <- appl / id
  appl        <- ws {| $appl id (ws id)+ |}
  id          <- ws {[^][%s,-=%(%)]+}
  ws          <- %s*
]]

parse = (s) ->
  ast = grammar\match s
  return ast or parserError "Failed to parse: #{s}"

{:parse}