-- typekit.parser.init
-- Main parser module for typekit signatures
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import parserError  from  require "typekit.parser.error"
import trim,
       isString,
       getlr        from  require "typekit.commons"

-- Signature format
-- f :: Cl a => a -> b -> c
-- f :: {a:b} -> {b:a}
-- f :: [a] -> [b]
-- f :: Eq a, Ord a => Maybe a -> Boolean
--   FUTURE?
--   f :: s -> (s, a)

-- Returns and removes the name for a signature, if exists
nameFor = (sig) ->
  log "parser.nameFor #got", inspect sig
  local name
  sig  = sig\gsub "^%s*(.+)%s*::%s*", (s) ->
    log "parser.nameFor", "#{s} ::"
    name = s
    ""
  return (trim name), sig

-- Merge constraints
-- Overrides current <- base
--   merge:
--     Eq a => a -> a
--     Ord a => a -> a -- clears Eq constraint
--   'a' does not have Eq constraint anymore but has Ord constraint.
mergeConstraints = (target, base) ->
  nt = {var, {const for const in *constl} for var, constl in pairs base}
  for var, constl in pairs base
    nt[var] = constl
  nt

-- Returns and removes the constraints in a signature
constraintsFor = (sig, pconstl={}) ->
  constl = {}
  sig         = sig\gsub "^%s*(.-)%s*=>%s*", (s) ->
    constl = [trim const for const in s\gmatch "[^,]+"]
    ""
  --
  constraints = {}
  for const in *constl
    parts = [part for part in const\gmatch "%S+"]
    if #parts > 2 then parserError "More than two applications in constraint #{inspect parts} in '#{sig}'"
    if constraints[parts[2]]
      table.insert constraints[parts[2]], parts[1]
    else
      constraints[parts[2]] = {parts[1]}
  --
  constraints = mergeConstraints pconstl, constraints
  --
  return constraints, sig

-- Base for checkParenthesis, checkList and checkTable
checkX = (fname, ochar, cchar, charname) -> (sig) ->
    log "parser.#{fname} #got", inspect sig
    return false if "string" != type sig
    i     = 0
    depth = 0
    over0 = 0 -- 0 -> hasnt gone over 0, 1 -> has gone over 1, 2 -> has gone back to 0 
    --
    canremove = true
    for ch in sig\gmatch "."
      i += 1
      log "parser.#{fname} #status", "#{i}: #{ch} (#{depth}) OVERZERO=#{over0}"
      switch ch
        when ochar then depth += 1
        when cchar then depth -= 1
      parserError "Mismatching #{charname} for signature '#{sig}' at col #{i}" if depth < 0
      switch over0
        when 0 then over0     = 1 if depth > 0
        when 1 then over0     = 2 if depth == 0
        when 2 then canremove = false
      log "parser.#{fname} #over", "over0 = 2" if over0 == 2
    --
    parserError "Mismatching #{charname} for signature '#{sig}' at col #{i}" if depth != 0
    canremove = false if over0 == 0
    log "parser.#{fname} #ret", "returning #{canremove}"
    canremove

-- Removes top-most parens
-- instead of using a pattern, has to be done manually to ensure they are the same parens
-- for that we use checkParens
checkParenthesis = checkX "checkParenthesis", "(", ")", "parenthesis"
removeParenthesis = (sig) -> if x = sig\match "^%s*%((.+)%)%s*$" then x else sig

-- turns [a] -> {container: "List", value: "a"}
checkList = checkX "checkList", "[", "]", "square brackets"
toList = (sig) ->
  return sig if "string" != type sig
  if x = sig\match "^%[(.+)%]$" then {container: "List", value: x} else sig

-- turns {a:b} -> {container: "Table", key: "a", value: "b"}
checkTable = checkX "checkTable", "{", "}", "curly brackets"
toTable = (sig) ->
  return sig if "string" != type sig
  key, value = sig\match "^{(.+):(.+)}$"
  if key and value
    return {container: "Table", :key, :value}
  else
    return sig

-- turns 'Maybe a' -> {data: "Maybe a", "Maybe", "a"}
checkApplication = (sig) ->
  return false if "string" != type sig
  return false if sig\match "%->"
  return false if not sig\match " "
  return false if sig\match "^[%{%[]"
  return true
toApplication = (sig) ->
  parts      = [part for part in sig\gmatch "%S+"]
  parts.data = sig
  return parts

-- Splits a signature in two by an arrow ->
-- returns tree
binarize = (sig, child=false, pname, pconstl) ->
  log "parser.binarize #got", sig
  sig = removeParenthesis sig if checkParenthesis sig
  
  -- Get name and constraints 
  name, sig    = nameFor sig
  constl, sig  = constraintsFor sig, pconstl

  -- If we are inside another signature, check if we are scoped.
  if child
    constl = mergeConstraints constl, pconstl
    if name != pname
      log "parser.binarize #name", "name changed from #{pname} to #{name}"
  
  -- Variables
  log "parser.binarize #sig", sig
  left, right = "", ""
  side        = false -- false -> left, true -> right
  depth       = 0
  flag        = {}

  -- Functions
  agglutinate = (ch) -> if side then right ..= ch else left ..= ch

  for char in sig\gmatch "." do
    log "parser.binarize #loop", inspect {
      :side
      :depth
      {:left, :right}
      await: flag.await_arrow
    }
    switch char
      when "("
        agglutinate char
        continue if side
        depth += 1
        flag.await_arrow = false
      when ")"
        agglutinate char
        continue if side
        depth -= 1
        flag.await_arrow = false
      when "-"
        flag.await_arrow = true if depth == 0
        agglutinate char if (depth > 0) or side
      when ">"
        if (depth > 0) or side
          agglutinate char
        elseif flag.await_arrow
          flag.await_arrow = false
          side             = true
        else agglutinate char
      else
        flag.await_arrow = false
        agglutinate char

  -- Fix arrowless functions
  if right == ""
    right = left
    left  = ""
  
  log "parser.binarize #ret", "#{left} >> #{right}"
  return {left: (trim left), right: (trim right), :name, :constl, signature: sig}

-- recursively binarize
rebinarize = (sig, child=false, pname, pconstl) ->
  S          = binarize sig, child, pname, pconstl
  l, r       = getlr S
  oldl, oldr = l, r
  --
  S.left  = toList        S.left  if checkList        S.left
  S.left  = toTable       S.left  if checkTable       S.left
  S.left  = toApplication S.left  if checkApplication S.left
  S.right = toList        S.right if checkList        S.right
  S.right = toTable       S.right if checkTable       S.right
  S.right = toApplication S.right if checkApplication S.right
  --
  S.left[#S.left]   = toList  S.left[#S.left]   if (S.left[1])  and checkList  S.left[#S.left]
  S.right[#S.right] = toList  S.right[#S.right] if (S.right[1]) and checkList  S.right[#S.right]
  S.left[#S.left]   = toTable S.left[#S.left]   if (S.left[1])  and checkTable S.left[#S.left]
  S.right[#S.right] = toTable S.right[#S.right] if (S.right[1]) and checkTable S.right[#S.right]
  --
  S.left = rebinarize S.left, true, S.name, S.constl if (isString S.left) and S.left\match "%->"
  log "parser.rebinarize #ch", "l: #{oldl} >> #{inspect l}" if S.left != oldl
  S.right = rebinarize S.right, true, S.name, S.constl if (isString S.right) and S.right\match "%->"
  log "parser.rebinarize #ch", "r: #{oldr} >> #{inspect r}" if S.right != oldr
  --
  S

{
  :nameFor, :constraintsFor, :getlr
  :mergeConstraints
  :binarize, :rebinarize
}