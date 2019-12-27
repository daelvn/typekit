(DEBUG) ->
  import inspect from require "debugkit.inspect"
  import logger  from require "debugkit.log"
  import style   from require "ansikit.style"

  io.stdout\setvbuf "no"

  typekitLgr         = logger.default!
  typekitLgr.name    = "typekit"
  typekitLgr.header  = (T) => style "%{bold green}#{@name}%{blue}.%{white}#{T} %{yellow}$ "
  typekitLgr.time    =     => ""

  typekitLgr.exclude = {
    -- parser.binarize
    "parser.binarize #loop"
    "parser.binarize #got"
    "parser.binarize #sig"
    "parser.binarize #ret"
    -- parser.rebinarize
    "parser.rebinarize #ch"
    -- parser.checkParenthesis
    "parser.checkParenthesis #match"
    "parser.checkParenthesis #over"
    "parser.checkParenthesis #status"
    "parser.checkParenthesis #ret"
    "parser.checkParenthesis #got"
    -- type.typeof.resolve
    "type.typeof.resolve #got"
    "type.typeof.resolve #resolved"
  }

  log                = typekitLgr!

  { :inspect, :log }