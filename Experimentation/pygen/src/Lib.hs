module Lib
    ( parseFile


    , PyIdent
    , PyExpr
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
    , (.:)
    ) where



import Language.Python.Common
import Language.Python.Version3


data NoAnnot = NoAnnot
  deriving (Eq, Show)

type PyIdent = Ident NoAnnot
type PyDotted = DottedName NoAnnot
type PyExpr = Expr NoAnnot
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

pyCall :: PyExpr -> [PyExpr] -> PyExpr
pyCall fn args = Call fn (map argument args) NoAnnot
  where
    argument e = ArgExpr e NoAnnot


pyWith :: PyExpr -> Maybe PyExpr -> PyStmts -> PyStmt
pyWith e i s = With [(e, i)] s NoAnnot

pyAssign :: PyExpr -> PyExpr -> PyStmt
pyAssign e1 e2 = Assign [e1] e2 NoAnnot

pyFn :: PyIdent -> [PyIdent] -> PyStmts -> PyStmt
pyFn name params body = Fun name (map parameter params) Nothing body NoAnnot
  where parameter x = Param x Nothing Nothing NoAnnot


-- Monad?

