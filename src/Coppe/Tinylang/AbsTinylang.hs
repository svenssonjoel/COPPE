-- Haskell data types for the abstract syntax.
-- Generated by the BNF converter.

module Coppe.Tinylang.AbsTinylang where

newtype Ident = Ident String
  deriving (Eq, Ord, Show, Read)

data Exp
    = ELam [Arg] Exp
    | ELet Exp Exp Exp
    | EIf Exp Exp Exp
    | EOr Exp Exp
    | EAnd Exp Exp
    | ENot Exp
    | ERel Exp RelOp Exp
    | EAdd Exp AddOp Exp
    | EMul Exp MulOp Exp
    | EApp Exp [AppArg]
    | EInt Integer
    | EFloat Double
    | EBool Boolean
    | EVar Ident
    | EString String
  deriving (Eq, Ord, Show, Read)

data AddOp = Plus | Minus
  deriving (Eq, Ord, Show, Read)

data MulOp = Times | Div
  deriving (Eq, Ord, Show, Read)

data RelOp = LTC | LEC | GTC | GEC | EQC
  deriving (Eq, Ord, Show, Read)

data Arg = ArgIdent Ident
  deriving (Eq, Ord, Show, Read)

data AppArg = AppArgExp Exp
  deriving (Eq, Ord, Show, Read)

data Boolean = BTrue | BFalse
  deriving (Eq, Ord, Show, Read)

