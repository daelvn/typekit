(DEBUG) ->
  unless DEBUG
    inspect = require "inspect"
    return {
      :inspect, log: (->), processor: {sign: process: (x)->(x)}
    }

  import inspect from require "debugkit.inspect"
  import logger  from require "debugkit.log"
  import style   from require "ansikit.style"

  io.stdout\setvbuf "no"

  typekitLgr         = logger.default!
  typekitLgr.name    = "typekit"
  typekitLgr.header  = (T) => style "%{bold green}#{@name}%{blue}.%{white}#{T} %{yellow}$ "
  typekitLgr.time    =     => ""

  typekitLgr.exclude = {
    -- parser.nameFor
    "parser.nameFor"
    "parser.nameFor #got"
    -- parser.binarize
    "parser.binarize #loop"
    "parser.binarize #got"
    "parser.binarize #sig"
    "parser.binarize #ret"
    "parser.binarize #name"
    -- parser.rebinarize
    "parser.rebinarize #ch"
    -- parser.checkParenthesis
    "parser.checkParenthesis #match"
    "parser.checkParenthesis #over"
    "parser.checkParenthesis #status"
    "parser.checkParenthesis #ret"
    "parser.checkParenthesis #got"
    -- parser.checkList
    "parser.checkList #match"
    "parser.checkList #over"
    "parser.checkList #status"
    "parser.checkList #ret"
    "parser.checkList #got"
    -- parser.checkTable
    "parser.checkTable #match"
    "parser.checkTable #over"
    "parser.checkTable #status"
    "parser.checkTable #ret"
    "parser.checkTable #got"
    -- parser.compareSide
    "parser.compareSide #types"
    -- type.resovleSynonym
    "type.resolveSynonym #got"
    -- type.typeof.resolve
    "type.typeof.resolve #got"
    "type.typeof.resolve #resolved"
    -- sign
    "sign #got"
    "sign #fn"
    "sign #cache"
    -- global
    "global.initG"
    "global.addReference #got"
  }

  log = typekitLgr!

  processor = {
    sign: process: (path) => -- item(@), path
      i = path[#path]
      --
      return nil if i == "type"
      return nil if i == "call"
      return nil if i == inspect.METATABLE
      return @
  }

  { :inspect, :log, :processor }