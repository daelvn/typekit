import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
native                 = type
type                   =  require "typekit.type"

BASIC = false
if BASIC
  import typeof from type
  log "type/test.typeof #check", typeof "a"
  log "type/test.typeof #check", typeof 5
  log "type/test.typeof #check", typeof true
  log "type/test.typeof #check", typeof typeof
  log "type/test.typeof #check", typeof typeof.resolvers[1]

CUSTOM = false
if CUSTOM
  import Resolver, registerResolver, typeof from type
  isPair = Resolver {
    name:    "isPair"
    resolve: (v) -> if ((native v) == "table") and v.l and v.r then "Pair" else false
    returns: {"Pair"}
  }
  --
  Pair = (l, r) -> {:l, :r}
  --
  registerResolver isPair
  --
  log "type/test.typeof #check", typeof Pair 1, 2

TABLE = true
if TABLE
  import typeofList, typeofTable from type
  log "type/test.typeof #check", typeofList {"a", "b", "c"}
  log "type/test.typeof #check", typeofList {1, 2, 3}
  --
  log "type/test.typeof #check", inspect {typeofTable {"a", "b", "c"}}