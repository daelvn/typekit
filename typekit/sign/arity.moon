-- typekit.sign.arity
-- Guesses the arity of a function given it's curried signature
-- By daelvn

-- Returns the arity for a signature AST.
arityFor = (ast) ->
  n = 0
  if ("table" == type ast) and ast.signature
    if ast.left then n += 1
    if ast.right then return n + arityFor ast.right 
  else return 0

{ :arityFor }
