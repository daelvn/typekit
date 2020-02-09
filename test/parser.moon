import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import compare      from  require "typekit.parser.compare"
parser                 =  require "typekit.parser"


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
  --"f :: ((a -> b) -> c) -> (d -> e)"
  "g :: b -> (a -> b) -> Maybe a -> b"
}

import getlr from parser

NAMES = false
if NAMES
  for i, sig in ipairs signatures
    import nameFor from parser
    n, sig = nameFor sig
    log "parser.test.nameFor", "#{inspect n} :: #{sig}"

CONSTRAINTS = false
if CONSTRAINTS
  for i, sig in ipairs signatures
    import constraintsFor from parser
    cl, sig       = constraintsFor sig
    log "parser.test.constraintsFor", "#{inspect cl} => #{sig}" if #cl > 0

BINARIZE = false
if BINARIZE
  for i, sig in ipairs signatures
    import binarize from parser
    S    = binarize sig 
    l, r = getlr S
    log "parser.test.binarize",              "#{l} >> #{r}"
    log "parser.test.binarize #name",        "#{S.name}"
    log "parser.test.binarize #constraints", "#{inspect S.constl}"

REBINARIZE = true
if REBINARIZE
  for i, sig in ipairs signatures
    import rebinarize from parser
    S    = rebinarize sig
    l, r = getlr S
    log "parser.test.rebinarize", "#{inspect l} >> #{inspect r}"

SUBSIGN = false
if SUBSIGN
  import rebinarize from parser
  S = rebinarize "Eq a => (Ord a => a -> a) -> a" 
  log "parser.test.rebinarize #subsign", inspect S

COMPARE = false
if COMPARE
  import rebinarize from parser
  Sa = rebinarize ">>=  :: Monad m => a -> m b"
  Sb = rebinarize ">>=' :: Monad Maybe => a -> Maybe b"
  --log "parser.test.rebinarize", inspect Sa
  log "parser.test.compare", inspect {compare Sa, Sb}