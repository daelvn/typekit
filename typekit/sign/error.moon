-- typekit.parser.error
-- Error reporting for the parser
import style from require "ansikit.style"

signError = (msg) ->
  print style "%{bold red}typekit (sign) $%{notBold} #{msg}"
  error!

{ :signError }