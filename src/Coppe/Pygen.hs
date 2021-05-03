{- Pygen.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Coppe.Pygen
    ( parseFile

    , PyModule
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
    , pySubscript
    , (.:)
    , (+:)
    , (-:)
    , (*:)
    , (/:)

    , glorot_uniform
    , glorot_applied

    , runPyGen
    , exampleProgram
    ) where

import Language.Python.Common
import Language.Python.Version3

import Control.Monad.State
import Control.Monad.Writer

data NoAnnot = NoAnnot
  deriving (Eq, Show)

type PyModule = Module NoAnnot
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

pyVarId :: PyIdent -> PyExpr
pyVarId i = Var i NoAnnot

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
pyTuple es = Paren (Tuple es NoAnnot) NoAnnot

pyList :: [PyExpr] -> PyExpr
pyList es = List es NoAnnot

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

pySubscript :: PyExpr -> PyExpr -> PyExpr
pySubscript e1 e2 = Subscript e1 e2 NoAnnot

-- Some arithmetic

(+:) :: PyExpr -> PyExpr -> PyExpr
(+:) e1 e2 = BinaryOp (Plus NoAnnot) e1 e2 NoAnnot

(-:) :: PyExpr -> PyExpr -> PyExpr
(-:) e1 e2 = BinaryOp (Minus NoAnnot) e1 e2 NoAnnot

(*:) :: PyExpr -> PyExpr -> PyExpr
(*:) e1 e2 = BinaryOp (Multiply NoAnnot) e1 e2 NoAnnot

(/:) :: PyExpr -> PyExpr -> PyExpr
(/:) e1 e2 = BinaryOp (Divide NoAnnot) e1 e2 NoAnnot

infixl 7 *:
infixl 7 /:
infixl 6 +:
infixl 6 -:

-- Examples
glorot_uniform seed shape a =
  pyCall  (
  pyCall  (pyDotted [pyIdent "tf", pyIdent "keras", pyIdent "initializers", pyIdent "glorot_uniform"]) [seed]
  ) [shape,a] 
  
glorot_applied =
  glorot_uniform (pyArgKey (pyIdent "seed") pyNone)
                 (pyArgKey (pyIdent "shape") (pyTuple [pyInt 3, pyInt 3, pyInt 3]))
                 (pyArg (pyInt 16))


-- PyGen monad

newtype PyGen a = PyGen (StateT Integer (Writer [PyStmt]) a)
  deriving (Functor, Applicative, Monad,  MonadState Integer, MonadWriter [PyStmt])

runPyGen :: PyGen PyModule -> PyModule
runPyGen (PyGen pm) = fst $ runWriter (evalStateT pm 0)


--type 

genUnique :: PyGen Integer
genUnique =
  do  i <- get
      put (i + 1)
      return i

genPyIdent :: PyGen PyIdent 
genPyIdent =
  do i <- genUnique
     return $ pyIdent ("gen_ident" ++ show i)

genPyVar :: PyGen PyExpr
genPyVar =
  do i <- genUnique
     return $ pyVar ("gen_var" ++ show i)

genModule :: PyGen () -> PyGen PyModule
genModule body =
  do body' <- censor (const []) $ snd <$> listen body
     return $ Module body'

genFunction :: PyIdent -> [PyIdent] -> ([PyIdent] -> PyGen ()) -> PyGen ()
genFunction name args body =
  do body' <- censor (const []) $ snd <$> listen (body args)
     tell [pyFn name args body']

genAssign :: PyIdent -> PyExpr -> PyGen ()
genAssign i e =
  do tell [pyAssign (pyVarId i) e] 

(=:) :: PyIdent -> PyExpr -> PyGen ()
(=:) = genAssign

infixl 1 =:

exampleProgram :: PyGen PyModule
exampleProgram =
   genModule $
   do
     genFunction (pyIdent "apa") [pyIdent "argument1", pyIdent "argument2"] $
       \ [a,b] ->
         do (pyIdent "x") =: ((pyVarId a) +: (pyVarId b))
            (pyIdent "y") =: glorot_applied
           
-- Module [
--   Fun {fun_name = Ident {ident_string = "apa", ident_annot = NoAnnot},
--        fun_args = [Param {param_name = Ident {ident_string = "a", ident_annot = NoAnnot}, param_py_annotation = Nothing, param_default = Nothing, param_annot = NoAnnot},Param {param_name = Ident {ident_string = "b", ident_annot = NoAnnot}, param_py_annotation = Nothing, param_default = Nothing, param_annot = NoAnnot}],
--        fun_result_annotation = Nothing,
--        fun_body = [Assign {assign_to = [Var {var_ident = Ident {ident_string = "x", ident_annot = NoAnnot}, expr_annot = NoAnnot}],
--                            assign_expr = BinaryOp {operator = Plus {op_annot = NoAnnot}, left_op_arg = Var {var_ident = Ident {ident_string = "a", ident_annot = NoAnnot}, expr_annot = NoAnnot}, right_op_arg = Var {var_ident = Ident {ident_string = "b", ident_annot = NoAnnot}, expr_annot = NoAnnot}, expr_annot = NoAnnot}, stmt_annot = NoAnnot},
--                     Assign {assign_to = [Var {var_ident = Ident {ident_string = "y", ident_annot = NoAnnot}, expr_annot = NoAnnot}],
--                             assign_expr = Call {call_fun = Call {call_fun = Dot {dot_expr = Dot {dot_expr = Dot {dot_expr = Var {var_ident = Ident {ident_string = "tf", ident_annot = NoAnnot}, expr_annot = NoAnnot}, dot_attribute = Ident {ident_string = "keras", ident_annot = NoAnnot}, expr_annot = NoAnnot}, dot_attribute = Ident {ident_string = "initializers", ident_annot = NoAnnot}, expr_annot = NoAnnot}, dot_attribute = Ident {ident_string = "glorot_uniform", ident_annot = NoAnnot}, expr_annot = NoAnnot}, call_args = [ArgKeyword {arg_keyword = Ident {ident_string = "seed", ident_annot = NoAnnot}, arg_expr = None {expr_annot = NoAnnot}, arg_annot = NoAnnot}], expr_annot = NoAnnot}, call_args = [ArgKeyword {arg_keyword = Ident {ident_string = "shape", ident_annot = NoAnnot},
--                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               arg_expr = Tuple {tuple_exprs = [Int {int_value = 3, expr_literal = "3", expr_annot = NoAnnot},Int {int_value = 3, expr_literal = "3", expr_annot = NoAnnot},Int {int_value = 3, expr_literal = "3", expr_annot = NoAnnot}], expr_annot = NoAnnot}, arg_annot = NoAnnot},ArgExpr {arg_expr = Int {int_value = 16, expr_literal = "16", expr_annot = NoAnnot}, arg_annot = NoAnnot}], expr_annot = NoAnnot}, stmt_annot = NoAnnot}], stmt_annot = NoAnnot}]
