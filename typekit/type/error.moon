-- typekit.parser.error
-- Error reporting for the parser
import style from require "ansikit.style"

typeError = (msg) ->
  print style "%{bold red}typekit (type) $%{notBold} #{msg}"
  error!

{ :typeError }