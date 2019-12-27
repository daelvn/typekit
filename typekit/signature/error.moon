-- typekit.parser.error
-- Error reporting for the parser
import style from require "ansikit.style"

parserError = (msg) ->
  print style "%{bold red}typekit (sign) $%{notBold} #{msg}"
  error!

{ :parserError }