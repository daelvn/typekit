-- typekit.parser.compare
-- By daelvn
-- Compare signature trees
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import contains,
       isString,
       isTable,
       isUpper,
       isLower      from  require "typekit.commons"

-- Compares two sets of constraints
compareConstraints = (base={}, target={}) ->
  log "parser.compareConstraints #got", inspect {:base, :target} if (#base > 0) and (#target > 0)
  for var, constl in pairs base
    return false unless target[var]
    for const in *constl
      return false unless contains target[var], const
  return true

-- Merge messages
mergeMessages = (a={}, b={}) ->
  n = {k, v for k, v in pairs a}
  for k, v in pairs b do n[k] = v
  n

-- Returns the case comparing uppercase and lowercase
caseFor = (base, against) ->
  -- cases:
  --   BASE    <-> AGAINST
  --   upper   === upper   (1)  must be equal and match constraints
  --   upper    ?  lower   (2)  must match constraints
  --   lower   <-- upper   (3)  cache upper, must match constraints
  --   lower    ?  lower   (4)  must match constraints
  -- @TODO The problem here is going to be dealing with tables and lists.
  iub, iua, ilb, ila = (isUpper base), (isUpper against), (isLower base), (isLower against)
  if iub and iua
    return 1
  elseif iub and ila
    return 2
  elseif ilb and iua
    return 3
  elseif ilb and ila
    return 4

local compare

-- compares string in a side
compareSide = (base, against, cache={}, side="left") ->
  -- @TODO Deal with type applications somewhere (Maybe [a] vs Maybe [Number], currently would not pass)
  -- @TODO Probably implement as a table data=true
  status, msg = false, nil
  bx, ax      = base[side], against[side]
  -- container/signature vs container/signature
  if (isTable bx) and (isTable ax)
    -- container vs container
    if bx.container and ax.container
      -- [a] vs [b]
      if ("List" == bx.container) and ("List" == ax.container)
        log "parser/compareSide #container", "delegating to compareSide again #1"
        status, msg, cache = compareSide {[side]: bx.value}, {[side]: ax.value}, cache, side
      -- [a] vs {b:c}
      elseif ("List" == bx.container) and ("Table" == ax.container)
        if ax.key != "number" -- only {Number:a} can compare with [a]
          status, msg = false, {[side]: "can't compare list with table with non-Number keys"}
        else
          log "parser/compareSide #container", "delegating to compareSide again #2"
          status, msg, cache = compareSide {[side]: bx.value}, {[side]: ax.value}, cache, side
      -- {a:b} vs [c]
      elseif ("Table" == bx.container) and ("List" == ax.container)
        if bx.key != "number" -- only [a] can compare with {Number:a}
          status, msg = false, {[side]: "can't compare list with table with non-Number keys"}
        else
          log "parser/compareSide #container", "delegating to compareSide again #3"
          status, msg, cache = compareSide {[side]: bx.value}, {[side]: ax.value}, cache, side
      -- {a:b} vs {c:d}
      elseif ("Table" == bx.container) and ("Table" == ax.container)
        log "parser/compareSide #container", "delegating key to compareSide"
        kstatus, kmsg, cache = compareSide {[side]: bx.key}, {[side]: ax.key}, cache, side
        log "parser/compareSide #container", "delegating value to compareSide"
        vstatus, vmsg, cache = compareSide {[side]: bx.value}, {[side]: ax.value}, cache, side
        -- success
        if kstatus and vstatus
          status, msg = true, {[side]: "success"}
        -- value failed
        elseif kstatus
          status, msg = vstatus, vmsg
        -- key failed
        elseif vstatus
          status, msg = kstatus, kmsg
        -- both failed
        else
          status, msg = false, (mergeMessages vmsg, kmsg)
      -- unknown vs unknown ???
      else status, msg = false, {[side]: "illegal container types '#{bx.container}' and '#{ax.container}'"}
    -- container vs signature
    elseif bx.container
      status, msg = false, {[side]: "attempt to compare container against signature '#{ax}'"}
    -- signature vs container
    elseif ax.container
      status, msg = false, {[side]: "attempt to compare container against signature '#{bx}'"}
    -- signature vs signature
    else
      status, msg, cache = compare bx, ax, cache
  -- container/signature vs simple
  elseif (isTable bx) and (isString ax)
    -- container vs simple
    if bx.container
      -- container vs Table
      if ax == "Table"
        status, msg = true, {[side]: "success"}
      -- container vs simple
      else
        status, msg = false, {[side]: "cannot compare list or table against '#{ax}'"}
    -- signature vs simple
    else
      status, msg = false, {[side]: "cannot compare signature against simple type"}
  -- simple vs container/signature
  elseif (isString bx) and (isTable ax)
    -- container vs simple
    if ax.container
      -- container vs Table
      if bx == "Table"
        status, msg = true, {[side]: "success"}
      -- container vs simple
      else
        status, msg = false, {[side]: "cannot compare list or table against '#{bx}'"}
    -- signature vs simple
    else
      status, msg = false, {[side]: "cannot compare signature against simple type"}
  -- simple vs simple 
  elseif (isString bx) and (isString ax)
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
  -- Removed to be able to compare containers and simple types
  --     if (type base) != (type against)
  --       return false, {both: "base and against are not same type"}, cache
  --     elseif (type base.left) != (type against.left)
  --       return false, {both: "left sides are not same type"}, cache
  --     elseif (type base.right) != (type against.right)
  --       return false, {both: "right sides are not same type"}, cache
  left,  leftmsg,  cache = compareSide base, against, cache, "left"
  right, rightmsg, cache = compareSide base, against, cache, "right"

  log "parser/compare #ret", "l:#{left} r:#{right}"
  if left and right
    return true, {both: "success"}, cache
  else
    return false, (mergeMessages leftmsg, rightmsg), cache

{ :compare }