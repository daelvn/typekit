-- typekit.parser.compare
-- Compare signature trees
-- By daelvn
import DEBUG          from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import resolveSynonym from  require "typekit.type"
import contains       from  require "typekit.commons"

-- Merge messages
mergeMessages = (a={}, b={}) ->
  n = {k, v for k, v in pairs a}
  for k, v in pairs b do n[k] = v
  n

-- Special empty table
EMPTY = setmetatable {}, __index: (i) =>
  if x = rawget @, i then return x else return {}

--# Combinators #--
-- Combinators take in a value and return a function that matches
-- against that value.
-- All combinators have the form:
--  (v, cv, side, cache) -> (x, cx) -> (boolean, table, table).
local Any, Variable, List, Table, Tuple, Application, Function

Any = (v, cv, side, cache={}) ->
  cv or= v.constraints or EMPTY
  log "compare #Any", "constructing for " .. inspect {
    :v, :cv, :side, :cache
    tag: v.tag
  }
  switch v.tag
    when "upper", "lower" then return Variable v, cv, side, cache
    when "list"           then return List v, cv, side, cache
    when "table"          then return Table v, cv, side, cache
    when "tuple"          then return Tuple v, cv, side, cache
    when "appl"           then return Application v, cv, side, cache
    when "fn"             then return Function v, cv, side, cache
    else return -> return false, {both: "unknown tag #{v.tag}"}, cache 
  
Variable = (v, cv, side, cache={}) ->
  cv or= v.constraints or EMPTY
  log "compare #Variable", "constructing for " .. inspect {
    :v, :cv, :side, :cache
  }
  switch v.tag
    when "upper"
      v[1] = resolveSynonym v[1]
      return (x, cx) ->
        cx or= x.constraints or EMPTY
        log "compare #Variable", "comparing for " .. inspect {
          base:    {:v, :cv, :side, :cache}
          against: {:x, :cx}
        }
        switch x.tag
          when "upper"
            x[1] = resolveSynonym x[1]
            for cst in *cv[v[1]] do unless contains (cx[x[1]] or {}), cst
              return false, {[side]: "expected constraint #{cst} on type #{x[1]}"}, cache
            if v[1] == x[1]
              return true
            else return false, {[side]: "expected type #{v[1]}, got #{x[1]}"}, cache
          when "lower"
            for cst in *cv[v[1]] do unless contains (cx[x[1]] or {}), cst
              return false, [side]: {"expected constraint #{cst} on variable #{x[1]}"}, cache
            cache[x[1]] = v[1]
            return true
          else return false, [side]: {"expected variable, got #{x.tag}"}, cache
    when "lower"
      return (x, cx) ->
        cx or= x.constraints or EMPTY
        log "compare #Variable", "comparing for " .. inspect {
          base:    {:v, :cv, :side, :cache}
          against: {:x, :cx}
        }
        switch x.tag
          when "upper"
            for cst in *cv[v[1]] do unless contains (cx[x[1]] or {}), cst
              return false, [side]: {"expected constraint #{cst} on type #{x[1]}"}, cache
            cache[v[1]] = resolveSynonym x[1]
            return true
          when "lower"
            for cst in *cv[v[1]] do unless contains (cx[x[1]] or {}), cst
              return false, [side]: {"expected constraint #{cst} on variable #{x[1]}"}, cache
            return true
          else return false, [side]: {"expected variable, got #{x.tag}"}, cache
    else -> return false, [side]: {"expected variable, got #{v.tag}"}, cache

List = (v, cv, side, cache={}) ->
  cv or= v.constraints or EMPTY
  log "compare #List", "constructing for " .. inspect {
    :v, :cv, :side, :cache
  }
  V1 = resolveSynonym v[1][1]
  if v.tag == "list"
    return (x, cx) ->
      cx or= x.constraints or EMPTY
      log "compare #List", "comparing for " .. inspect {
        base:    {:v, :cv, :side, :cache}
        against: {:x, :cx}
      }
      switch x.tag
        when "list"
          return (Variable v[1], cv, side, cache) x[1], cx
        when "table"
          X1, X2 = (resolveSynonym x[1][1]), (resolveSynonym x[2][1])
          if X1 != "Number"
            return false, {[side]: "expected [#{V1}], got {#{X1}:#{X2}}"}, cache
          return (Variable v[1], cv, side, cache) x[2], cx
        when "upper"
          X1 = resolveSynonym x[1]
          if X1 == "Table"
            return true
          else
            return false, {[side]: "expected Table, got #{X1}"}, cache
        else return false, {[side]: "expected list, got #{x.tag}"}, cache
  else -> return false, {[side]: "expected list, got #{v.tag}"}, cache

Table = (v, cv, side, cache={}) ->
  cv or= v.constraints or EMPTY
  log "compare #Table", "constructing for " .. inspect {
    :v, :cv, :side, :cache
  }
  V1, V2 = (resolveSynonym v[1][1]), (resolveSynonym v[2][1])
  if v.tag == "table"
    return (x, cx) ->
      cx or= x.constraints or EMPTY
      log "compare #List", "comparing for " .. inspect {
        base:    {:v, :cv, :side, :cache}
        against: {:x, :cx}
      }
      switch x.tag
        when "list"
          X1 = resolveSynonym x[1][1]
          if V1 != "Number"
            return false, {[side]: "expected {#{V1}:#{V2}}, got [#{X1}]"}
          return (Variable v[2], cv, side, cache) x[1], cx
        when "table"
          --X1, X2        = (resolveSynonym x[1][1]), (resolveSynonym x[2][1])
          sk, ek, cache = (Variable v[1], cv, side, cache) x[1], cx
          sv, ev, cache = (Variable v[2], cv, side, cache) x[2], cx
          if sk and sv
            return true
          elseif sv
            return false, ek, cache
          elseif sk
            return false, ev, cache
          else
            return false, (mergeMessages ek, ev), cache
        when "upper"
          X1 = resolveSynonym x[1]
          if X1 == "Table"
            return true
          else
            return false, {[side]: "expected Table, got #{X1}"}, cache
        else return false, {[side]: "expected {#{V1}:#{V2}}, got #{v.tag}"}, cache
  else -> return false, {[side]: "expected table, got #{v.tag}"}, cache

Tuple = (v, cv, side, cache={}) ->
  cv or= v.constraints or EMPTY
  log "compare #Tuple", "constructing for " .. inspect {
    :v, :cv, :side, :cache
  }
  len = #v
  if v.tag == "tuple"
    return (x, cx) ->
      cx = x.constraints or cx or EMPTY
      log "compare #Tuple", "comparing for " .. inspect {
        base:    {:v, :cv, :side, :cache}
        against: {:x, :cx}
      }
      if x.tag != "tuple"
        return false, {[side]: "expected application, got #{x.tag}"}, cache
      if len != #x
        return false, {[side]: "tuples are not the same length"}, cache
      for i, ty in ipairs v
        ty               = resolveSynonym ty
        stat, err, cache = (Any ty, cv, side, cache) x[i], cx
        unless stat
          return false, err, cache
      return true
  else -> return false, {[side]: "expected tuple, got #{v.tag}"}, cache

Application = (v, cv, side, cache={}) ->
  cv or= v.constraints or EMPTY
  log "compare #Application", "constructing for " .. inspect {
    :v, :cv, :side, :cache
  }
  len = #v
  if v.tag == "appl"
    return (x, cx) ->
      cx or= x.constraints or EMPTY
      log "compare #List", "comparing for " .. inspect {
        base:    {:v, :cv, :side, :cache}
        against: {:x, :cx}
      }
      if x.tag != "appl"
        return false, {[side]: "expected application, got #{x.tag}"}, cache
      if len != #x
        return false, {[side]: "applications are not the same length"}, cache
      for i, ty in ipairs v
        ty               = resolveSynonym ty
        stat, err, cache = (Any ty, cv, side, cache) x[i], cx
        unless stat
          return false, err, cache
      return true
  else -> return false, {[side]: "expected application, got #{v.tag}"}, cache

Function = (v, cv, side, cache={}) ->
  cv = v.constraints or cv or EMPTY
  log "compare #Function", "constructing for " .. inspect {
    :v, :cv, :side, :cache
  }
  if v.tag == "fn"
    VL, VR = v.left, v.right
    return (x, cx) ->
      cx = x.constraints or cx or {}
      log "compare #Function", "comparing for " .. inspect {
        base:    {:v, :cv, :side, :cache}
        against: {:x, :cx}
      }
      if x.tag != "fn"
        return false, {[side]: "expected function, got #{x.tag}"}, cache
      XL, XR        = x.left, x.right
      sl, el, cache = (Any VL, cv, "left", cache)  XL, cx
      sr, er, cache = (Any VR, cv, "right", cache) XR, cx
      if sl and sr
        return true
      elseif sl
        return false, er, cache
      elseif sr
        return false, el, cache
      else
        return false, (mergeMessages er, el), cache
  else -> return false, {[side]: "expected function, got #{v.tag}"}, cache

-- import parse from require "typekit.parser.init-re"
-- s1 = parse "map  :: Eq a => (a -> b) -> [a] -> [b]"
-- s2 = parse "map' :: Eq x => (x -> y) -> [x] -> [y]"

-- shape = Any s1
-- stat, err, cache = shape s2

-- print stat, (inspect err), (inspect cache)

{ 
  :Any, :Variable, :List, :Table, :Tuple, :Application, :Function
  compare: Any
}