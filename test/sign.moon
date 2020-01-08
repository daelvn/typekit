import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import sign         from require "typekit.sign"

id = sign "id :: a -> a"
id (x) -> x

log "MOT/1", inspect id 5

add = sign "add :: Number -> Number -> Number"
add (a) -> (b) -> a + b

add1 = add 1

map = sign "map :: (a -> b) -> [a] -> [b]"
map (f) -> (l) -> [f v for v in *l]

log "MOT/2", inspect (map add1) {1, 2, 3}