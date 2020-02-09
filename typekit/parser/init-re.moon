-- typekit.parser.init
-- Parser for typekit signatures written in re
-- By daelvn
import parserError  from  require "typekit.parser.error"
import empty        from  require "typekit.commons"
re                     =  require "re"

shorthand = (s) ->
  s = s\gsub "$(%S+)", [[{:tag: "" -> "%1" :}]]
  return s

grammar = re.compile shorthand [[
  -- signature parser
  signature   <- ws function
  
  group       <- ws "(" ws (function / complex) ws ")"
  function    <- ws {| $fn name? constraints? {:left: gc :} ws "->" ws {:right: (group / function / complex) :} |}
  complex     <- tuple / table / list / type

  constraints <- ws {:constraints: {| typelist |} :} ws "=>" ws
  name        <- ws {:name: {valid+} :} ws "::" ws

  tuple       <- ws "(" {| $tuple gclist        |} ")"
  table       <- ws "{" {| $table type ":" type |} "}"
  list        <- ws "[" {| $list  type          |} "]"

  gclist      <- gc ("," ws gc)*
  gc          <- group / complex
  typelist    <- type ("," ws type)*
  type        <- appl / id
  appl        <- ws {| $appl id (ws id)+ |}

  id          <- uc / lc
  lc          <- ws {| $lower {%l valid*} |}
  uc          <- ws {| $upper {%u valid*} |}
  valid       <- [^][%s,-=%(%)]
  ws          <- %s*
]]

reduceConstraints = (node) ->
  if node.constraints
    cl = {}
    for ct in *node.constraints
      coll = {}
      for i, part in ipairs ct
        if i == #ct
          if cl[part[1]]
            for v in *coll
              table.insert cl[part[1]], v
          else
            cl[part[1]] = coll
          coll = {}
        else
          table.insert coll, part[1]
    node.constraints = setmetatable cl, __index: (i) =>
      if x = rawget @, i then return x else return {}
  for _, v in pairs node
    reduceConstraints v if ("table" == type v) and (not empty v)
  return node
    

parse = (s) ->
  ast = reduceConstraints grammar\match s
  return ast or parserError "Failed to parse: #{s}"

--print (require"inspect") reduceConstraints parse "Eq a, Ord a => a -> b"
  
{ :parse }