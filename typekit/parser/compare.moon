-- typekit.parser.compare
-- By daelvn
-- Compare signature trees
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import classesFor   from  require "typekit.type.class"
import contains,
       isString,
       isTable,
       isUpper,
       isLower,
       empty        from  require "typekit.commons"

-- Compares two sets of constraints
-- We also get bx and ax because we don't want *any* variable with the same constraints
compareConstraints = (base={}, target={}, bx, ax) ->
  log "parser.compareConstraints #got", inspect {:base, :target, :bx, :ax}
  return true, "" if (empty base) and (empty target)
  -- can check for constraints
  if isUpper ax
    sel = base[bx]
    cll = classesFor ax
    for tc in *sel
      return false, "'#{ax}' is lacking constraint '#{tc}'" unless contains cll, tc
    return true, ""
  -- cannot check for constraints
  else
    sel = base[bx]
    agt = target[ax]
    return true,  ""                           unless sel
    return false, "'#{ax}' has no constraints" unless agt
    for tc in *sel
      return false, "'#{ax}' is lacking constraint #{tc}" unless contains agt, tc
    return true, ""


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
  status, msg = false, nil
  bx, ax      = base[side], against[side]
  log "parser.compareSide #got", inspect {
    :base, :against, :cache, :side, :bx, :ax
  }
  -- util functions
  sd = (x, y={constl:{}}) -> {[side]: x, constl: y.constl}
  -- container/signature vs container/signature
  log "parser.compareSide #types", inspect {(type bx), (type ax)}
  if (isTable bx) and (isTable ax)
    -- appl vs appl
    if bx.data and ax.data
      status, msg = compareSide (sd bx[#bx]), (sd ax[#ax]), cache, side
      if #bx != #ax
        status, msg = false, {[side]: "different amount of applications in '#{bx.data}' and '#{ax.data}'"}
      else
        status, msg = true, {}
        for i=1,(#bx-1)
          lstat, lmsg, cache = compareSide (sd bx[i], base), (sd ax[i], against), cache, side
          unless lstat
            status, msg = lstat, lmsg
            break
    -- container vs container
    elseif bx.container and ax.container
      -- [a] vs [b]
      if ("List" == bx.container) and ("List" == ax.container)
        log "parser.compareSide #container", "delegating to compareSide again #1"
        status, msg, cache = compareSide (sd bx.value, base), (sd ax.value, against), cache side
      -- [a] vs {b:c}
      elseif ("List" == bx.container) and ("Table" == ax.container)
        if ax.key != "number" -- only {Number:a} can compare with [a]
          status, msg = false, {[side]: "can't compare list with table with non-Number keys"}
        else
          log "parser.compareSide #container", "delegating to compareSide again #2"
          status, msg, cache = compareSide (sd bx.value, base), (sd ax.value, against), cache, side
      -- {a:b} vs [c]
      elseif ("Table" == bx.container) and ("List" == ax.container)
        if bx.key != "number" -- only [a] can compare with {Number:a}
          status, msg = false, {[side]: "can't compare list with table with non-Number keys"}
        else
          log "parser.compareSide #container", "delegating to compareSide again #3"
          status, msg, cache = compareSide (sd bx.value, base), (sd ax.value, against), cache, side
      -- {a:b} vs {c:d}
      elseif ("Table" == bx.container) and ("Table" == ax.container)
        log "parser.compareSide #container", "delegating key to compareSide"
        kstatus, kmsg, cache = compareSide (sd bx.key, base), (sd ax.key, against), cache, side
        log "parser.compareSide #container", "delegating value to compareSide"
        vstatus, vmsg, cache = compareSide (sd bx.value, base), (sd ax.value, against), cache, side
        -- success
        if kstatus and vstatus
          status, msg = true, {}
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
      status, msg = false, {[side]: "attempt to compare container against signature '#{ax.signature}'"}
    -- signature vs container
    elseif ax.container
      status, msg = false, {[side]: "attempt to compare container against signature '#{bx.signature}'"}
    -- signature vs signature
    elseif bx.signature and ax.signature
      status, msg, cache = compare bx, ax, cache
    -- ???
    else
      status, msg = false, {[side]: "illegal table types"}
  -- container/signature vs simple
  elseif (isTable bx) and (isString ax)
    -- container vs simple
    if bx.container
      -- container vs Table
      if ax == "Table"
        status, msg = true, {}
      -- container vs typevar
      elseif isLower ax
        status, msg, cache = compareSide (sd "Table", base), (sd ax, against), cache, side
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
        status, msg = true, {}
      -- container vs typevar
      elseif isLower bx
        status, msg, cache = compareSide (sd "Table", base), (sd bx, against), cache, side
      -- container vs simple
      else
        status, msg = false, {[side]: "cannot compare list or table against '#{bx}'"}
    -- signature vs simple
    else
      status, msg = false, {[side]: "cannot compare signature against simple type"}
  -- simple vs simple 
  elseif (isString bx) and (isString ax)
    log "parser.compareSide #const", inspect {
      "Comparing constraints"
      :base, :against
    }
    ccstatus, ccerr = compareConstraints base.constl, against.constl, bx, ax
    switch caseFor bx, ax
      when 1 -- upper === upper   (1) must be equal and match constraints
        if bx != ax
          status, msg = false, {[side]: "type '#{ax}' does not match expected type '#{bx}'"}
        elseif not ccstatus
          status, msg = false, {[side]: "constraints do not match: #{ccerr}"}
        else
          status, msg = true, {}
      when 2 -- upper  ?  lower   (2) must match constraints
        unless ccstatus
          status, msg = false, {[side]: "constraints do not match: #{ccerr}"}
        else
          status, msg = true, {}
      when 3 -- lower <-- upper   (3) cache upper, must match constraints
        unless ccstatus
          status, msg = false, {[side]: "constraints do not match: #{ccerr}"}
        else
          if cache[bx] -- found in cache
            if cache[bx] != ax
              status, msg = false, {[side]: "expected #{cache[bx]} (#{bx}), got #{ax}"}
            else
              status, msg = true, {}
          else -- not found in cache
            cache[bx] = ax
            status, msg = true, {}
      when 4 -- lower  ?  lower   (4) must match constraints
        unless ccstatus
          status, msg = false, {[side]: "constraints do not match: #{ccerr}"}
        else
          status, msg = true, {}
  log "parser.compareSide #ret", inspect {:status, :msg, :cache}
  return status, msg, cache

-- compare two nodes
compare = (base, against, cache={}) ->
  log "parser.compare #got", inspect {:base, :against, :cache}
  left,  leftmsg,  cache = compareSide base, against, cache, "left"
  right, rightmsg, cache = compareSide base, against, cache, "right"

  log "parser.compare #ret", "l:#{left} r:#{right}"
  if left and right
    return true, {}, cache
  else
    return false, (mergeMessages leftmsg, rightmsg), cache

{ :compareSide, :compare }