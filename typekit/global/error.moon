-- typekit.global.error
-- Error reporting for stubs and subfunctions
import style from require "ansikit.style"

stubError = (msg) ->
  print style "%{bold red}typekit (stub) $%{notBold} #{msg}"
  error!

{ :stubError }