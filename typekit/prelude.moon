-- typekit.prelude
-- Basic types, functions and typeclasses
-- To be imported in most projects
-- By daelvn
import DEBUG          from  require "typekit.config"
import inspect, log   from (require "typekit.debug") DEBUG
import sign           from  require "typekit.sign"
import kindof         from  require "typekit.type"
import Type           from  require "typekit.type.data"
unpack or= table.unpack

--# Maybe #--

-- typedef
Maybe = Type "Maybe a",
  Nothing: ""
  Just:    "a"
Option = Maybe
import Nothing, Just from Maybe.constructor

-- maybe
maybe = sign "b -> (a -> b) -> Maybe a -> b"
maybe (d) -> (f) -> (x) -> switch x
  when Nothing then return d
  else              return f x[1]

--# Either #--
Either = Type "Either l r",
  Left:  "l"
  Right: "r"
import Left, Right from Either.constructor

-- either
either = sign "(l -> c) -> (r -> c) -> Either l r -> c"
either (fl) -> (fr) -> (e) -> switch kindof e
  when "Left"  then return fl e[1]
  when "Right" then return fr e[1]

--# Ordering #--
Ordering = Type "Ordering",
  LT: "", EQ: "", GT: ""
import LT, EQ, GT from Ordering.constructor

--# Pair #--
Pair = Type "Pair a b", Tuple: "a b"
import Tuple from Pair.constructor

-- fst
fst = sign "Pair a b -> a"
fst (p) -> p[1]

-- snd
snd = sign "Pair a b -> b"
snd (p) -> p[2]

--# miscellaneous functions #--

id = sign "a -> a"
id (x) -> x

const = sign "a -> b -> a"
const (c) -> -> c

compose = sign "(b -> c) -> (a -> b) -> a -> c"
compose (fa) -> (fb) -> (x) -> fa fb x

flip = sign "(a -> b -> c) -> b -> a -> c"
flip (f) -> (b) -> (a) -> (f a) b

until_ = sign "(a -> Boolean) -> (a -> a) -> a -> a"
until_ (p) -> (f) -> (v) -> if p! then return f v else return v

asTypeOf = sign "a -> a -> a"
asTypeOf (c) -> -> c

--# list operations #--

map = sign "(a -> b) -> [a] -> [b]"
map = (f) -> (t) -> [f v for v in *t]

append = sign "[a] -> [a] -> [a]"
append (tg) -> (fr) ->
  table.insert tg, v for v in *fr
  tg

filter = sign "(a -> Bool) -> [a] -> [a]"
filter (p) -> (xs) -> [x for x in *xs when p x]

head = sign "[a] -> a"
head (xs) -> xs[1]

last = sign "[a] -> a"
last (xs) -> xs[#xs]

tail = sign "[a] -> [a]"
tail (xs) -> {select 2, unpack xs}

init = sign "[a] -> [a]"
init (xs) -> [v for i, v in ipairs xs when i != #xs]

reverse = sign "[a] -> [a]"
reverse (xs) -> [xs[i] for i=#xs,1,-1]

take = sign "Number -> [a] -> [a]"
take (n) -> (xs) -> [v for i, v in ipairs xs when i <= n]

drop = sign "Number -> [a] -> [a]"
drop (n) -> (xs) -> {select n, unpack xs}