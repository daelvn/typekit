(DEBUG) ->
  import inspect from require "debugkit.inspect"
  import logger  from require "debugkit.log"
  import style   from require "ansikit.style"

  typekitLgr        = logger.default!
  typekitLgr.name   = "typekit"
  typekitLgr.header = (T) => style "%{bold green}#{@name} %{blue}- %{white}#{T} %{yellow}$ "
  typekitLgr.time   =     => ""
  log               = typekitLgr!

  { :inspect, :log }