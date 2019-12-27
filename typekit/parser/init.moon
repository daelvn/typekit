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
-- f :: Eq Ord a, Ord a => Maybe a -> Boolean

-- Trims spaces around a string
trim = (str) -> if x = str\match "^%s*(.-)%s*$" then x else str

-- Returns and removes the name for a signature, if exists
nameFor = (sig) ->
  name = false
  sig  = sig\gsub "^%s*(.+)%s*::%s*", (s) ->
    name = s
    ""
  return (trim name), sig

-- Returns and removes the constraints in a signature
constraintsFor = (sig) ->
  constraints = {}
  sig         = sig\gsub "^%s*(.+)%s*=>%s*", (s) ->
    constraints = [trim const for const in s\gmatch "[^,]+"]
    ""
  return constraints, sig

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
binarize = (sig) ->
  log "parser.binarize #got", sig
  sig         = removeParenthesis sig if checkParenthesis sig
  log "parser.binarize #sig", sig
  left, right = "", ""
  side        = false -- false -> left, true -> right
  depth       = 0
  flag        = {}

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
        -- aggl char
        agglutinate char
        -- continue if right side
        continue if side
        -- increase depth
        depth += 1
        -- make sure > only happens after -
        flag.await_arrow = false
      when ")"
        -- aggl char
        agglutinate char
        -- continue if right side
        continue if side
        -- reduce depth
        depth -= 1
        -- make sure > only happens after -
        flag.await_arrow = false
      when "-"
        -- make sure > only happens after -
        flag.await_arrow = true if depth == 0
        -- aggl char if inside parens or right side
        agglutinate char if (depth > 0) or side
      when ">"
        -- aggl char if inside parens or right side
        if (depth > 0) or side
          agglutinate char
        -- change side if - was previous character
        elseif flag.await_arrow
          flag.await_arrow = false
          side             = true
        else agglutinate char
      else -- other chraracters
        -- make sure > only happens after -
        flag.await_arrow = false
        agglutinate char

  -- Fix arrowless functions
  if right == ""
    right = left
    left  = ""
  log "parser.binarize #ret", "#{left} >> #{right}"
  return {(trim left), (trim right)}

-- recursively binarize
rebinarize = (sig) ->
  l, r       = unpack binarize sig
  oldl, oldr = l, r
  l = rebinarize l if l\match "%->"
  log "parser.rebinarize #ch", "l: #{oldl} >> #{inspect l}" if l != oldl
  r = rebinarize r if r\match "%->"
  log "parser.rebinarize #ch", "r: #{oldr} >> #{inspect r}" if r != oldr
  {l, r}

-- checks if first is uppercase/lowercase
isUpper = (str) -> str\match"^%u" or false
isLower = (str) -> str\match"^%l" or false

-- compares two strings
compareStrings = (a, b, cache) ->
  return if (isUpper a) and (isUpper b)
    -- have to be equal. A == A
    a == b
  elseif (isUpper a) and (isLower b)
    -- b <- a
    cache[b] = a
    true
  elseif (isLower a) and (isUpper b)
    -- a <- b
    cache[a] = b
    true
  elseif (isLower a) and (isLower b)
    -- always true
    true
  else parserError "Type '#{a}' or '#{b}' do not start with a letter."

-- compares a side of the signature tree
compareSide = (a, b, cache={}) ->
  if (type a) != (type b) then parserError "Mismatching types during compare. Signature A is #{type l}, signature B is #{type r}"
  switch type a
    when "string" then return compareStrings a, b
    when "table"  then return true

-- compares two signature trees
compare = (siga, sigb) ->
  na, siga = nameFor siga
  nb, sigb = nameFor sigb
  ca, siga = constraintsFor siga
  cb, sigb = constraintsFor sigb
  la, ra   = unpack rebinarize siga
  lb, rb   = unpack rebinarize sigb
  --
  log "parser.compare #got", "Comparing \"#{na} :: #{inspect ca} => #{inspect siga}\" with \"#{nb} :: #{inspect cb} => #{inspect sigb}\""
  return (compareSide la, lb) and (compareSide ra, rb)

{
  :nameFor, :constraintsFor
  :binarize, :rebinarize
  :compare
}