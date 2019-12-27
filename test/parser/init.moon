import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
parser                 =  require "typekit.parser"
unpack or= table.unpack

signatures = {
  --"fa :: Cl a => a -> b -> c"
  --"fb :: {a:b} -> {b:a}"
  --"fc :: [a] -> [b]"
  --"fd :: Eq Ord a, Ord a => Maybe a -> Boolean"
  --"a :: a"
  --"b :: a -> b"
  --"c :: a -> b -> c"
  --"d :: (a -> b) -> c"
  --"e :: a -> b -> c -> d -> e"
  "f :: ((a -> b) -> c) -> (d -> e)"
}

NAMES = false
for i, sig in ipairs signatures
  import nameFor from parser
  n, sig        = nameFor sig
  signatures[i] = sig
  log "parser/test.nameFor", "#{inspect n} :: #{sig}" if NAMES

CONSTRAINTS = false
for i, sig in ipairs signatures
  import constraintsFor from parser
  cl, sig       = constraintsFor sig
  signatures[i] = sig
  log "parser/test.constraintsFor", "#{inspect cl} => #{sig}" if CONSTRAINTS and (#cl > 0)

BINARIZE = false
for i, sig in ipairs signatures
  import binarize from parser
  l, r = unpack binarize sig
  log "parser/test.binarize", "#{l} >> #{r}" if BINARIZE

REBINARIZE = false
for i, sig in ipairs signatures
  import rebinarize from parser
  l, r = unpack rebinarize sig
  log "parser/test.rebinarize", "#{inspect l} >> #{inspect r}" if REBINARIZE
  
COMPARE = true
if COMPARE
  import compare from parser
  siga = "map :: (a -> b) -> [a] -> [b]"
  sigb = "map' :: (x -> y) -> [x] -> [y]"
  log "parser/test.compare", compare siga, sigb