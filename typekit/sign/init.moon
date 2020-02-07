-- typekit.sign.init
-- Signing functions for type checking
-- By daelvn

-- 5.1 Compat
unpack or= table.unpack

-- Debugging
import DEBUG          from  require "typekit.config"
import inspect, log,
       processor      from (require "typekit.debug") DEBUG
-- Erroring
import signError,
       errorf         from  require "typekit.sign.error"
-- Types
import typeof,
       typeofTable,
       typeofList,
       resolveSynonym from  require "typekit.type"
import classesFor     from  require "typekit.type.class"
-- Parser
import compare,
       compareSide    from  require "typekit.parser.compare"
import rebinarize     from  require "typekit.parser"
-- Utils
import metatype,
       empty,
       clone,
       setfenv,
       uncurry,
       bind,
       keysIn,
       getPair,
       isUpper,
       isLower       from  require "typekit.commons"
-- Pattern matching
import match,
       advance       from  require "typekit.type.match"
-- Arity
import arityFor      from  require "typekit.sign.arity"

-- To reuse earlier in the code
local sign

-- Always compares to teuw
TKTrue = (metatype "TKTrue") {}

-- Parses a single type instead of a function
selr = (T) -> (T == "string") and (rebinarize T).right or T

-- check side
checkSide = (argx, side, constl={}, cache={}, patl={}) =>
  this  = @tree[side]
  errf  = (errorf @name, @signature, @safe, @silent) true
  warnf = (errorf @name, @signature, @safe, @silent) false
  -- Logging
  log "sign.checkSide #got",     inspect {:self, :argx, :side, :constl, :cache}, processor.sign
  log "sign.checkSide #expects", inspect {:this}
  -- Selecting only first argument since uncurried functions
  -- are not supported anymore. This is a design choice.
  arg   = argx[1]
  argxr = nil
  -- Skip if TKTrue
  if "TKTrue" == typeof arg
    log "sign.checkSide #ret", inspect {:argx, :constl, :cache}
    return argx[2], constl, cache
  -- Type synonyms
  this = selr resolveSynonym this
  -- Util functions
  sd = (x) -> {[side]: x, :constl}
  -- Select type for side
  -- signed function
  if this.signature
    -- Expects function, check what we got
    if "Function" == typeof arg
      -- Difference between signed and unsigned
      if "table" == type arg -- signed
        status, err, cache = compare this, arg.tree, cache
        if status
          argxr = arg
        else
          errf "Functions do not compare", {
            "Expected: #{this.signature}"
            "Got:      #{arg.signature}"
            ((err.left or err.right) and "---" or nil)
            (err.left  and "Left:  #{err.left}"  or nil)
            (err.right and "Right: #{err.right}" or nil)
          }
      elseif "function" == type arg -- unsigned
        warnf "Cannot compare signed function against unsigned function", {
          "Signed function:   #{this.signature}"
          "Unsigned function: #{arg}"
          (@safe and nil or "---")
          (@safe or "Will be automatically subsigned since @safe is #{@safe}")
        }
        argxr = (sign this.signature, constl, cache, patl) arg
      else -- ???
        errf "Expected Function, got #{typeof arg} (#{type arg})"
    else
      errf "Expected Function, got #{typeof arg}"
  -- datatype
  elseif this.data
    -- {"Either", "l", "r"}
    expect = this[1]
    ehas   = [eh for eh in *this[2,]]
    if isUpper expect -- do all checks
      if expect != typeof arg
        errf "Expected '#{this.data}', got '#{typeof arg}'"
      -- @IMPL x = Just 5; x[1] = 5
      -- @IMPL "Maybe a";  x.expects = 1
      if #ehas != keysIn arg
        errf "Expected #{#ehas} value(s), got #{keysIn arg}"
      for i=1, #ehas
        bx, ax = ehas[i], arg[i]
        -- Delegate to compare
        status, err, cache = compareSide (sd bx), (sd typeof ax), cache, side
        unless status
          errf "Could not compare '#{inspect bx}%{red}' against '#{inspect typeof ax}%{red}'", {
            "in '#{this.data}' against '#{typeof arg}'"
            "variable ##{i}"
            ((err.left or err.right) and "---" or nil)
            (err.left  and "Left:  #{err.left}"  or nil)
            (err.right and "Right: #{err.right}" or nil)
          }
        elseif isLower expect -- compare constraints and add to cache (delegate)
          -- {"m", "a"} (Monads?)
          expect = this[1]
          got    = arg[1]
          status, err, cache = compareSide (sd expect), (sd got), cache, side
          unless status
            errf "Could not compare '#{inspect expect}' against '#{inspect got}'", {
              "in '#{this.data}' against '#{arg.data}'"
              "variable #0"
              ((err.left or err.right) and "---" or nil)
              (err.left  and "Left:  #{err.left}"  or nil)
              (err.right and "Right: #{err.right}" or nil)
            }
          for i=2, #this
            bx, ax = this[i], arg[i]
            -- Delegate to compare
            status, err, cache = compareSide (sd bx), (sd ax), cache, side
            unless status
              errf "Could not compare '#{inspect bx}' against '#{inspect ax}'", {
                "in '#{this.data}' against '#{arg.data}'"
                "variable ##{i}"
                ((err.left or err.right) and "---" or nil)
                (err.left  and "Left:  #{err.left}"  or nil)
                (err.right and "Right: #{err.right}" or nil)
              }
    argxr = arg
  -- container
  elseif this.container
    if "table" != type arg
      errf "Attempt to compare #{this.container} to #{type arg}"
    switch this.container
      when "List"
        ttk, ttv = typeofTable arg
        if (ttk != "Number") or not (compareSide (sd ttv), (sd this.value), cache, side)
          errf "Attempt to compare {#{ttk}:#{ttv}} to [#{this.value}]", {
            "Expected: {Number:#{this.value}}"
          }
        argxr = arg
      when "Table"
        ttk, ttv = typeofTable arg
        if (ttk != this.key) or not (compareSide (sd ttv), (sd this.value), cache, side)
          errf "Attempt to compare {#{ttk}:#{ttv}} to {#{this.key}:#{this.value}}"
        argxr = arg
      else
        errf "Unknown container type '#{this.container}'"
  -- simple type
  else
    -- possibly delegate to compare?
    status, err, cache = compareSide (sd this), (sd typeof arg), cache, side
    unless status
      errf "Could not compare '#{this}' against '#{typeof arg}'", {
        (err.left  and "Left:  #{err.left}"  or nil)
        (err.right and "Right: #{err.right}" or nil)
      }
    argxr = arg
  
  -- Success
  log "checkSide #ret", inspect {:argxr, :constl, :cache}
  return argxr, constl, cache

-- Wraps a signed constructor
wrap ==> (argl, constl={}, cache, patl={}, vars) ->
  log "wrap #self", inspect @, processor.sign
  local argm
  if @tree.left == ""
    log "wrap #got", "no left side"
    argm = {@.call!}
  else
    -- Check passed arguments
    local i1
    if @ignore1 or vars
      log "wrap #i1", "#{inspect argl[1]} #{inspect argl}"
      i1 = table.remove argl, 1
      log "wrap #i1", "#{inspect i1}, #{inspect argl}"
    log "wrap #got", inspect {@name, :argl, :constl, :cache}, processor.sign
    argi, constl, cache = checkSide @, argl, "left", constl, cache, patl
    -- Run function
    log "wrap #run", inspect {:argi, :constl, :cache}, processor.sign
    log "wrap #fn",  inspect @call
    if vars
      --@ignore1 = true
      argm = {@.call TKTrue, vars, argi}
    else
      argm = {@.call argi}
    log "wrap #ran", inspect {:argm, :constl, :cache}, processor.sign
  -- Check returned arguments
  argo, constl, cache = checkSide @, argm, "right", constl, cache, patl
  log "wrap #ret", inspect {:argo, :constl, :cache}, processor.sign
  -- Return
  -- if @ignore1 or vars
  --   table.insert argo, 1, i1
  return argo

-- Signs a function
sign = (sig, constl={}, cache, patl={}) ->
  log "sign #got", sig
  -- Generate tree
  tree = rebinarize sig, false, nil, constl
  -- Return object
  return setmetatable {
    signature: sig
    :tree
    name:      tree.name
    call:      false
    patterns:  patl
    --
    safe:      false -- Werror
    silent:    false -- Silence warnings
    ignore1:   false -- Ingores the first argument passed to function
  }, {
    __kind: "Signed"
    __type: "SignedConstructor"
    -- add patterns
    __newindex: (cs, fn) =>
      if "Case" == typeof cs
        if "Function" == typeof fn
          log "sign #newpat", inspect {arityFor @tree}
          if #cs == arityFor @tree
            log "sign #newpat", "Adding pattern ##{keysIn @patterns}"
            patsig = if @name
              @signature\gsub @name, "#{@name}$#{keysIn @patterns}"
            else
              @signature
            @patterns[cs] = (sign patsig) fn
            -- Set self metatype to Function, since it can already be called
            (metatype "Function") @
          else signError "Case should be #{expects @tree} arguments long, got #{#cs} instead."
        else signError "Expected Function, got #{typeof fn}"
      else signError "Expected Case, got #{typeof cs}"
    -- define or call the function
    __call: (...) =>
      log "sign #call", "calling #{@name}"
      --log "sign #got2", inspect @, processor.sign
      switch typeof @
        when "SignedConstructor"
          f = select 1, ...
          if "Function" == typeof f
            log "sign #fn", "Setting to #{f}"
            @call = f
          else
            signError "Expected Function, got #{typeof f}"
          -- Set self metatype to Function
          (metatype "Function") @
        when "Function"
          -- using (cache or {}) instead of 'cache={}' fixes cache issues
          -- for some unknown reason
          log "sign #cache",   inspect (cache or {})
          log "sign #pattern", keysIn @patterns
          if 0 == keysIn @patterns
            -- no patterns to match
            return (wrap @) {...}, constl, (cache or {})
          else
            -- patterns to match
            arg = ({...})[1]
            -- lets build a list of the patterns that do match
            vars     = {}
            matching = {}
            for cs, fn in pairs @patterns
              vars[cs] = match cs, 1, arg
              if vars[cs] then matching[cs] = fn
            log "sign #pattern", "matched #{keysIn matching}"
            switch keysIn matching
              when 0
                -- none matched, check for default
                if @call
                  return (wrap @) {...}, constl, (cache or {})
                else signError "Patterns are not exhaustive enough"
              when 1
                -- one matched, use that function
                cs, @call = getPair matching
                varl      = {}
                for k, v in pairs vars[cs] do varl[k] = v
                log "sign #vars", inspect varl
                -- env       = do
                --   x = clone _G
                --   for k, v in pairs vars[cs] do x[k] = v
                --   x
                --@call = setfenv @call, env
                log "sign #wrap", "self is #{typeof @}"
                return (wrap @) {TKTrue, ...}, constl, (cache or {}), {}, varl
              else
                -- matched more than one
                -- bind argument to all functions since it will work
                for cs, fn in pairs matching
                  log "sign #advance", "advancing matches. binding #{inspect arg, processor.match}"
                  matching[cs]           = nil
                  matching[(advance cs)] = (setfenv ((bind fn) arg), vars[cs])
                log "sign #call", "call is #{typeof @call}"
                return with (sign @signature, constl, cache, matching) (@call or ->)
                  .safe   = @safe
                  .silent = @silent
        else
          signError "Invalid constructor type #{typeof @}"
  }

{ :sign }