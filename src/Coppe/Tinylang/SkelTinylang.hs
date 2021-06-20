module Coppe.Tinylang.SkelTinylang where

-- Haskell module generated by the BNF converter

import Coppe.Tinylang.AbsTinylang
import Coppe.Tinylang.ErrM
type Result = Err String

failure :: Show a => a -> Result
failure x = Bad $ "Undefined case: " ++ show x

transIdent :: Ident -> Result
transIdent x = case x of
  Ident string -> failure x
transExp :: Exp -> Result
transExp x = case x of
  ELam args exp -> failure x
  ELet exp1 exp2 exp3 -> failure x
  EIf exp1 exp2 exp3 -> failure x
  EOr exp1 exp2 -> failure x
  EAnd exp1 exp2 -> failure x
  ENot exp -> failure x
  ERel exp1 relop exp2 -> failure x
  EAdd exp1 addop exp2 -> failure x
  EMul exp1 mulop exp2 -> failure x
  EApp exp appargs -> failure x
  EInt integer -> failure x
  EFloat double -> failure x
  EBool boolean -> failure x
  EVar ident -> failure x
  EString string -> failure x
transAddOp :: AddOp -> Result
transAddOp x = case x of
  Plus -> failure x
  Minus -> failure x
transMulOp :: MulOp -> Result
transMulOp x = case x of
  Times -> failure x
  Div -> failure x
transRelOp :: RelOp -> Result
transRelOp x = case x of
  LTC -> failure x
  LEC -> failure x
  GTC -> failure x
  GEC -> failure x
  EQC -> failure x
transArg :: Arg -> Result
transArg x = case x of
  Arg ident -> failure x
transAppArg :: AppArg -> Result
transAppArg x = case x of
  AppArg exp -> failure x
transBoolean :: Boolean -> Result
transBoolean x = case x of
  BTrue -> failure x
  BFalse -> failure x

