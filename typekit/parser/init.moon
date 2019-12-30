-- typekit.parser.init
-- Main parser module for typekit signatures
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import parserError  from  require "typekit.parser.error"
unpack or= table.unpack

-- Signature format
-- f :: Cl a => a -> b -> c
-- f :: {a:b} -> {b:a}
-- f :: [a] -> [b]
-- f :: Eq a, Ord a => Maybe a -> Boolean

-- Trims spaces around a string
trim = (str) ->
  if str == nil                   then return nil
  if x = str\match "^%s*(.-)%s*$" then x            else str

-- Checks if a table contains an element
contains = (t, elem) ->
  for _, v in pairs t
    return true if elem == v
  return false 

-- Gets left and right for a signature
getlr = (sig) -> return sig.left, sig.right

-- Returns and removes the name for a signature, if exists
nameFor = (sig) ->
  local name
  sig  = sig\gsub "^%s*(.+)%s*::%s*", (s) ->
    log "parser.nameFor", "got #{s}"
    name = s
    ""
  return (trim name), sig

-- Returns and removes the constraints in a signature
constraintsFor = (sig) ->
  constl = {}
  sig         = sig\gsub "^%s*(.-)%s*=>%s*", (s) ->
    constl = [trim const for const in s\gmatch "[^,]+"]
    ""
  --
  constraints = {}
  for const in *constl
    parts = [part for part in const\gmatch "%S+"]
    if #parts > 2 then parserError "More than two applications in constraint #{inspect parts} in '#{signature}'"
    if constraints[parts[2]]
      table.insert constraints[parts[2]], parts[1]
    else
      constraints[parts[2]] = {parts[1]}
  --
  return constraints, sig

-- Compares two sets of constraints
compareConstraints = (base, target) ->
  for var, constl in pairs base
    return false unless target[var]
    for const in *constl
      return false unless contains target[var], const
  return true

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

-- Checks that all parenthesis match and whether the top-most parens can be removed
checkParenthesis = (sig) ->
  log "parser.checkParenthesis #got", sig
  i     = 0
  depth = 0
  over0 = 0 -- 0 -> hasnt gone over 0, 1 -> has gone over 1, 2 -> has gone back to 0 
  --
  canremove = true
  for ch in sig\gmatch "."
    i += 1
    log "parser.checkParenthesis #status", "#{i}: #{ch} (#{depth}) OVERZERO=#{over0}"
    switch ch
      when "(" then depth += 1
      when ")" then depth -= 1
    parserError "Mismatching parenthesis for signature '#{sig}' at col #{i}" if depth < 0
    switch over0
      when 0 then over0     = 1 if depth > 0
      when 1 then over0     = 2 if depth == 0
      when 2 then canremove = false
    log "parser.checkParenthesis #over", "over0 = 2" if over0 == 2
  --
  parserError "Mismatching parenthesis for signature '#{sig}' at col #{i}" if depth != 0
  log "parser.checkParenthesis #ret", "returning #{canremove}"
  canremove

-- Removes top-most parens
-- instead of using a pattern, has to be done manually to ensure they are the same parens
-- for that we use checkParens
removeParenthesis = (sig) -> if x = sig\match "^%s*%((.+)%)%s*$" then x else sig

-- Splits a signature in two by an arrow ->
-- returns tree
binarize = (sig, child=false, pname, pconstl) ->
  log "parser.binarize #got", sig
  sig = removeParenthesis sig if checkParenthesis sig
  
  -- Get name and constraints 
  name, sig    = nameFor sig
  constl, sig  = constraintsFor sig

  -- If we are inside another signature, check if we are scoped.
  if child
    if name != pname
      log "parser.binarize #scope", "name changed from #{pname} to #{name}"
    elseif not compareConstraints constl, pconstl
      log "parser.binarize #scope", "constraints changed, merging #{inspect constl} into #{inspect pconstl}"
      constl = mergeConstraints pconstl, constl
      log "parser.binarize #scope", "constraints merged, result is #{inspect constl}"

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
  return {left: (trim left), right: (trim right), :name, :constl}

-- recursively binarize
rebinarize = (sig, child=false, pname, pconstl) ->
  S          = binarize sig, child, pname, pconstl
  l, r       = getlr S
  oldl, oldr = l, r
  l = rebinarize l, true, S.name, S.constl if l\match "%->"
  log "parser.rebinarize #ch", "l: #{oldl} >> #{inspect l}" if l != oldl
  r = rebinarize r, true, S.name, S.constl if r\match "%->"
  log "parser.rebinarize #ch", "r: #{oldr} >> #{inspect r}" if r != oldr
  {left: l, right: r, name: S.name, constl: S.constl}

{
  :nameFor, :constraintsFor
  :getlr
  :compareConstraints, :mergeConstraints
  :binarize, :rebinarize
}