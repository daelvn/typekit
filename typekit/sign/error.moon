-- typekit.parser.error
-- Error reporting for the parser
import style from require "ansikit.style"

signError = (msg) ->
  print style "%{bold red}typekit (sign) $%{notBold} #{msg}"
  error!

fnWarn = (name="typekit", sig) -> (msg, details={}) ->
  print style "%{bold yellow}#{sig}"
  print style "%{     yellow}warning: #{msg}"
  if #details > 0
    print style "%{   yellow}==========================="
  for detail in *details
    print style "%{         }  #{detail}"

fnError = (name="typekit", sig) -> (msg, details={}) ->
  print style "%{bold red}#{sig}"
  print style "%{     red}error: #{msg}"
  if #details > 0
    print style "%{   red}=============================="
  for detail in *details
    print style "%{      }  #{detail}"
  error!

errorf = (name="typekit", sig, safe=false, silent=false) ->
  (err=false) -> (msg, details={}) ->
    if err or safe
      (fnError name, sig) msg, details
    elseif not silent
      (fnWarn name, sig)  msg, details

{ :signError, :errorf }