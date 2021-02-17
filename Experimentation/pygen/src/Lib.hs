module Lib
    ( parseFile


    , PyIdent
    , PyExpr
    , PyArg
    , PyDotted
    , PyStmt
    , PyStmts
    --
    , pyIdent
    , pyVar
    , pyStrings
    , pyImport
    , pyCall
    , pyWith
    , pyAssign
    , pyFn
    , pyNone
    , pyTuple
    , pyArg
    , pyArgKey
    , pyInt
    , pyFloat
    , pyDot
    , pyDotted
    , (.:)

    , glorot_uniform
    , glorot_applied
    ) where

import Language.Python.Common
import Language.Python.Version3

import Control.Monad.State

data NoAnnot = NoAnnot
  deriving (Eq, Show)

type PyIdent = Ident NoAnnot
type PyDotted = DottedName NoAnnot
type PyExpr = Expr NoAnnot
type PyArg  = Argument NoAnnot
type PyStmt = Statement NoAnnot
type PyStmts = [PyStmt]

parseFile :: FilePath -> IO (Either ParseError (ModuleSpan, [Token]))
parseFile fn = do
  fstr <- readFile fn
  return $ parseModule fstr fn 


pyIdent :: String -> PyIdent
pyIdent s = Ident s NoAnnot

pyVar :: String -> PyExpr
pyVar s = Var (pyIdent s) NoAnnot

pyStrings :: String -> PyExpr
pyStrings s = Strings [s] NoAnnot

(.:) :: PyDotted -> PyIdent -> PyDotted
(.:) dotted i = dotted ++ [i]

pyImport :: PyDotted -> Maybe PyIdent -> Statement NoAnnot
pyImport dotted mi = Import [ImportItem dotted mi NoAnnot] NoAnnot

pyCall :: PyExpr -> [PyArg] -> PyExpr
pyCall fn args = Call fn args NoAnnot

pyWith :: PyExpr -> Maybe PyExpr -> PyStmts -> PyStmt
pyWith e i s = With [(e, i)] s NoAnnot

pyAssign :: PyExpr -> PyExpr -> PyStmt
pyAssign e1 e2 = Assign [e1] e2 NoAnnot

pyFn :: PyIdent -> [PyIdent] -> PyStmts -> PyStmt
pyFn name params body = Fun name (map parameter params) Nothing body NoAnnot
  where parameter x = Param x Nothing Nothing NoAnnot

pyNone :: PyExpr
pyNone = None NoAnnot

pyTuple :: [PyExpr] -> PyExpr
pyTuple es = Tuple es NoAnnot

pyArg :: PyExpr -> PyArg
pyArg e = ArgExpr e NoAnnot

pyArgKey :: PyIdent -> PyExpr -> PyArg
pyArgKey i e = ArgKeyword i e NoAnnot

pyInt :: Integer -> PyExpr
pyInt i = Int i (show i) NoAnnot

pyFloat :: Double -> PyExpr
pyFloat f = Float f (show f) NoAnnot


pyDot :: PyExpr -> PyIdent -> PyExpr
pyDot e a = Dot e a NoAnnot

pyDotted :: [PyIdent] -> PyExpr
pyDotted [] = error "pyDotted: Cannot dot the empty list"
pyDotted [x] = error "pyDotted: Need at least 2 elements to dot"
pyDotted (e:es) = dotit (Var e NoAnnot) es 
  where
    dotit e [i] = pyDot e i
    dotit e (i:is) = dotit (pyDot e i) is


-- Examples
glorot_uniform seed shape a =
  pyCall  (
  pyCall  (pyDotted [pyIdent "tf", pyIdent "keras", pyIdent "initializers", pyIdent "glorot_uniform"]) [seed]
  ) [shape,a] 
  
glorot_applied =
  glorot_uniform (pyArgKey (pyIdent "seed") pyNone)
                 (pyArgKey (pyIdent "shape") (pyTuple [pyInt 3, pyInt 3, pyInt 3]))
                 (pyArg (pyInt 16))


-- Monad?


