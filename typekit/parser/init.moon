-- typekit.parser.init
-- Main parser module for typekit signatures
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import parserError  from  require "typekit.parser.error"

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
  log "parser.contains #got", inspect {:t, :elem}
  for _, v in pairs t
    return true if elem == v
  return false 

-- check for strings
isString = (v) -> "string" == (type v)

-- lowercase and uppercase detection
isUpper = (s) -> s\match "^%u"
isLower = (s) -> s\match "^%l"

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

-- Compares two sets of constraints
compareConstraints = (base, target) ->
  log "parser.compareConstraints #got", inspect {:base, :target}
  for var, constl in pairs base
    return false unless target[var]
    for const in *constl
      return false unless contains target[var], const
  return true

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

-- turns [a] -> {container: "List", value: "a"}
toList = (sig) ->
  log "parser.toList #got", sig
  i     = 0
  depth = 0
  over0 = 0 -- 0 -> hasnt gone over 0, 1 -> has gone over 1, 2 -> has gone back to 0 
  --
  canremove = true
  for ch in sig\gmatch "."
    i += 1
    log "parser.toList #status", "#{i}: #{ch} (#{depth}) OVERZERO=#{over0}"
    switch ch
      when "[" then depth += 1
      when "]" then depth -= 1
    parserError "Mismatching brackets for signature '#{sig}' at col #{i}" if depth < 0
    switch over0
      when 0 then over0     = 1 if depth > 0
      when 1 then over0     = 2 if depth == 0
      when 2 then canremove = false
    log "parser.toList #over", "over0 = 2" if over0 == 2
  --
  parserError "Mismatching brackets for signature '#{sig}' at col #{i}" if depth != 0
  log "parser.toList #ret", "can remove? #{canremove}"
  if canremove
    return {container: "List", value: sig\match "^%[(.+)%]$"}
  else
    return sig

-- turns {a:b} -> {container: "Table", key: "a", value: "b"}
toTable = (sig) ->
  log "parser.toTable #got", sig
  i     = 0
  depth = 0
  over0 = 0 -- 0 -> hasnt gone over 0, 1 -> has gone over 1, 2 -> has gone back to 0 
  --
  canremove = true
  for ch in sig\gmatch "."
    i += 1
    log "parser.toTable #status", "#{i}: #{ch} (#{depth}) OVERZERO=#{over0}"
    switch ch
      when "[" then depth += 1
      when "]" then depth -= 1
    parserError "Mismatching brackets for signature '#{sig}' at col #{i}" if depth < 0
    switch over0
      when 0 then over0     = 1 if depth > 0
      when 1 then over0     = 2 if depth == 0
      when 2 then canremove = false
    log "parser.toTable #over", "over0 = 2" if over0 == 2
  --
  parserError "Mismatching brackets for signature '#{sig}' at col #{i}" if depth != 0
  log "parser.toTable #ret", "can remove? #{canremove}"
  if canremove
    key, value = sig\match "^{(.+):(.+)}$"
    if key and value
      return {container: "Table", :key, :value}
    else
      return sig
  else
    return sig

-- Splits a signature in two by an arrow ->
-- returns tree
binarize = (sig, child=false, pname, pconstl) ->
  log "parser.binarize #got", sig
  sig = removeParenthesis sig if checkParenthesis sig
  
  -- Get name and constraints 
  name, sig    = nameFor sig
  constl, sig  = constraintsFor sig, pconstl

  --name   = pname   if name == ""
  --constl = pconstl if #constl == 0

  -- If we are inside another signature, check if we are scoped.
  if child
    if name != pname
      log "parser.binarize #name", "name changed from #{pname} to #{name}"
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
  l          = toList toTable l
  r          = toList toTable r
  l = rebinarize l, true, S.name, S.constl if (isString l) and l\match "%->"
  log "parser.rebinarize #ch", "l: #{oldl} >> #{inspect l}" if l != oldl
  r = rebinarize r, true, S.name, S.constl if (isString r) and r\match "%->"
  log "parser.rebinarize #ch", "r: #{oldr} >> #{inspect r}" if r != oldr
  {left: l, right: r, name: S.name, constl: S.constl}

-- Returns the case comparing uppercase and lowercase
caseFor = (base, against) ->
  -- cases:
  --   BASE    <-> AGAINST
  --   upper   === upper   (1)  must be equal and match constraints
  --   upper    ?  lower   (2)  must match constraints
  --   lower   <-- upper   (3)  cache upper, must match constraints
  --   lower    ?  lower   (4)  must match constraints
  -- @TODO The problem here is going to be dealing with tables and lists.
  if     (isUpper base) and (isUpper against)
    return 1
  elseif (isUpper base) and (isLower against)
    return 2
  elseif (isLower base) and (isUpper against)
    return 3
  elseif (isLower base) and (isLower against)
    return 4

local compare

-- compares string in a side
compareSide = (base, against, cache={}, side="left") ->
  status, msg = false, nil
  bx, ax      = base[side], against[side]
  if "table" == type bx
    if bx.container
      -- @FIXME this solution is good and all but what about lists (tables) against simple types (strings)
      -- @FIXME will probably have to remove the "same type" check
    else
      status, msg = compare bx, ax, cache
  elseif "string" == type bx
    switch caseFor bx, ax
      when 1 -- upper === upper   (1) must be equal and match constraints
        if bx != ax
          status, msg = false, {[side]: "type '#{ax}' does not match expected type '#{bx}'"}
        elseif not compareConstraints base.constl, against.constl
          status, msg = false, {[side]: "constraints in #{side} side do not match"}
        else
          status, msg = true, {[side]: "success"}
      when 2 -- upper  ?  lower   (2) must match constraints
        unless compareConstraints base.constl, against.constl
          status, msg = false, {[side]: "constraints in #{side} side do not match"}
        else
          status, msg = true, {[side]: "success"}
      when 3 -- lower <-- upper   (3) cache upper, must match constraints
        unless compareConstraints base.constl, against.constl
          status, msg = false, {[side]: "constraints in #{side} side do not match"}
        else
          cache[bx] = ax
          status, msg = true, {[side]: "success"}
      when 4 -- lower  ?  lower   (4) must match constraints
        unless compareConstraints base.constl, against.constl
          status, msg = false, {[side]: "constraints in #{side} side do not match"}
        else
          status, msg = true, {[side]: "success"}
  return status, msg, cache

-- compare two nodes
compare = (base, against, cache={}) ->
  log "parser/compare #got", inspect {:base, :against, :cache}
  if (type base) != (type against)
    return false, {both: "base and against are not same type"}, cache
  elseif (type base.left) != (type against.left)
    return false, {both: "left sides are not same type"}, cache
  elseif (type base.right) != (type against.right)
    return false, {both: "right sides are not same type"}, cache
  --
  left,  leftmsg,  cache = compareSide base, against, cache, "left"
  right, rightmsg, cache = compareSide base, against, cache, "right"

  if (not left) and (not right)
    log "parser/compare #lr", "notl notr"
    return false, {left: leftmsg, right: rightmsg}, cache
  elseif (not left) and right
    log "parser/compare #lr", "notl r"
    return false, {left: leftmsg}, cache
  elseif left and not right
    log "parser/compare #lr", "l notr"
    return false, {right: rightmsg}, cache
  elseif left and right
    log "parser/compare #lr", "l r"
    return true, {both: "success"}, cache

{
  :nameFor, :constraintsFor, :getlr
  :compareConstraints, :mergeConstraints
  :binarize, :rebinarize
  :compare
}