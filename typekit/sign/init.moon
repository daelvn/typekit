-- typekit.sign.init
-- Signing functions for type checking
-- By daelvn
import DEBUG         from  require "typekit.config"
import inspect, log  from (require "typekit.debug") DEBUG
import signError,
       errorf        from  require "typekit.sign.error"
import typeof,
       typeofTable,
       typeofList    from  require "typekit.type"
import classesFor    from  require "typekit.type.class"
import compare       from  require "typekit.parser.compare"
import rebinarize    from  require "typekit.parser"
import metatype,
       isUpper,
       isLower       from  require "typekit.commons"

local sign

-- check side
checkSide = (argx, side, constl={}, cache={}) =>
  -- TODO Cache handling
  this = @[side]
  err  = (errorf @name, @signature, @safe, @silent) true
  warn = (errorf @name, @signature, @safe, @silent) false
  -- Selecting only first argument since uncurried functions
  -- are not supported anymore. This is a design choice.
  arg  = argx[1]
  argi = nil
  -- Select type for side
  -- signed function
  if this.signature
    -- Expects function, check what we got
    if "Function" == typeof arg
      -- Difference between signed and unsigned
      if "table" == type arg -- signed
        status, err, cache = compare this, arg, cache
        if status
          argi = arg
        else
          err "Functions do not compare", {
            "Expected: #{this.signature}"
            "Got:      #{arg.signature}"
            "---"
            "Left:  #{err.left}"
            "Right: #{err.right}"
          }
      elseif "function" == type arg -- unsigned
        warn "Cannot compare signed function against unsigned function", {
          "Signed function:   #{this.signature}"
          "Unsigned function: #{arg}"
          "---"
          (@safe or "Will be automatically subsigned since @safe is #{@safe}")
        }
        argi = (sign this.signature) arg
      else -- ???
        err "Expected Function, got #{typeof arg} (#{type arg})"
    else
      err "Expected Function, got #{typeof arg}"
  -- datatype
  elseif this.data
    expect = this[1]
    ehas   = [eh for eh in *this[2,]]
    if expect != typeof arg -- FIXME Not accounting for lowercase
      err "Expected '#{this.data}', got '#{typeof arg}'"
    -- @IMPL x = Just 5; x[1] = 5
    -- @IMPL "Maybe a";  x.__expects = 1
    if #ehas != arg.__expects
      err "Expected #{#ehas} values, got #{arg.__expects}"
    for i=1, #ehas
      bx, ax = ehas[i], arg[i+1]
      -- Delegate to compare
      status, err, cache = compare {[side]: bx}, {[side]: ax}, cache
      unless status
        err "Could not compare '#{bx}' tp '#{ax}'", {
          "in '#{this.data}' against '#{arg.data}'"
          "variable ##{i}"
          "---"
          "Left:  #{err.left}"
          "Right: #{err.right}"
        }
    argi = arg
  -- container
  elseif this.container
    if "table" != type arg
      err "Attempt to compare #{this.container} to #{type arg}"
    switch this.container
      when "List"
        ttk, ttv = typeofTable arg
        if (ttk != "Number") or (ttv != this.value) -- FIXME Not accounting for lowercase
          err "Attempt to compare {#{ttk}:#{ttv}} to [#{this.value}]", {
            "Expected: {Number:#{this.value}}"
          }
        argi = arg
      when "Table"
        ttk, ttv = typeofTable arg
        if (ttk != this.key) or (ttv != this.value) -- FIXME Not accounting for lowercase
          err "Attempt to compare {#{ttk}:#{ttv}} to {#{this.key}:#{this.value}}"
        argi = arg
      else
        err "Unknown container type '#{this.container}'"
  -- simple type
  else
    return
  
  -- Success
  return true


-- Wraps a signed constructor
wrap ==> (argl, constl={}, cache={})
  -- Check passed arguments
  argi, constl, cache = checkSide @, argl, "left", constl, cache
  -- Run function
  argm = {@call unpack argi}
  -- Check returned arguments
  argo, constl, cache = checkSide @, argm, "right", constl, cache
  -- Return
  return unpack argo

-- Signs a function
sign = (sig, constl={}, cache={}) ->
  log "sign #got", sig
  -- Generate tree
  tree = rebinarize sig, false, nil, constl
  -- Return object
  return setmetatable {
    signature: sig
    :tree
    name:      tree.name
    type:      typeof
    call:      false
    --
    safe:      false -- Werror
    silent:    false -- Silence warnings
  }, {
    __type: "SignedConstructor"
    __call: (...) =>
      switch typeof @
        when "SignedConstructor"
          -- Check that we are getting a function
          f = select 1, ...
          if "Function" == typeof f
            @call = f
          else
            signError "Expected Function, got #{typeof f}"
          -- Set self metatype to Function
          (metatype "Function") @
        when "Function"
          log "sign #cache", inspect cache
          return (wrap @) {...}, constl, cache
        else
          signError "Invalid constructor type #{typeof @}"
  }

f = sign "f :: a -> b"
f (x) -> x
--
--_f = (_x) ->
--  check _x, "a"
--  _r = {f _x}
--  check _r, "b"