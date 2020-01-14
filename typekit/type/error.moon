-- typekit.parser.error
-- Error reporting for the parser
import style from require "ansikit.style"

typeError = (msg, details={}) ->
  print style "%{bold red}typekit (type) $%{notBold} #{msg}"
  if #details > 0
    print style "%{   red}=============================="
  for detail in *details
    print style "%{      }  #{detail}"
  error!

{ :typeError }