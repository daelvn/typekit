-- typekit.tableshape
-- leafo/tableshape mappings to make it simpler to use
-- By daelvn
import typeof, kindof from require "typekit.type"
ts                       = require "tableshape"
tl                       = ts.types

{
  Optional:  (x) -> x\is_optional!
  Describe:  (S) -> (d) -> S\describe d
  Tag:       (S) -> (t) -> S\tag t
  Transform: (S) -> (x) -> S\transform x
  Type:      (i) -> tl[i]
  T:         (i) -> tl[i]

  Shape:      tl.shape,      S:  tl.shape
  Partial:    tl.partial,    Pt: tl.partial
  oneOf:      tl.one_of
  Pattern:    tl.pattern,    P:  tl.pattern
  Array:      tl.array_of,   A:  tl.array_of
  contains:   tl.array_contains
  Map:        tl.map_of,     M:  tl.map_of
  Literal:    tl.literal,    L:  tl.literal
  Custom:     tl.custom,     C:  tl.custom
  Equivalent: tl.equivalent, E:  tl.equivalent
  Range:      tl.range,      R:  tl.range

  TKType: (x, f) -> (tl.custom (v) ->
    if (typeof x) != typeof v
      return nil, "expected type #{typeof x}"
    if (kindof x) != kindof v
      return nil, "expected kind #{kindof x}"
    return true
  ) * (tl.partial [f y for y in *x])
}