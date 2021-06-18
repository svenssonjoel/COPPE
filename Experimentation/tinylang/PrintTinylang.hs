{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module PrintTinylang where

-- pretty-printer generated by the BNF converter

import AbsTinylang
import Data.Char


-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else (' ':s))

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: Int -> [a] -> Doc
  prtList i = concatD . map (prt i)

instance Print a => Print [a] where
  prt = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)


instance Print Ident where
  prt _ (Ident i) = doc (showString ( i))



instance Print Exp where
  prt i e = case e of
    ELam args exp -> prPrec i 0 (concatD [doc (showString "fun"), prt 0 args, doc (showString "->"), prt 0 exp])
    ELet exp1 exp2 exp3 -> prPrec i 0 (concatD [doc (showString "let"), prt 0 exp1, doc (showString "="), prt 0 exp2, doc (showString "in"), prt 0 exp3])
    EIf exp1 exp2 exp3 -> prPrec i 0 (concatD [doc (showString "if"), prt 0 exp1, doc (showString "then"), prt 0 exp2, doc (showString "else"), prt 0 exp3])
    EOr exp1 exp2 -> prPrec i 1 (concatD [prt 2 exp1, doc (showString "||"), prt 1 exp2])
    EAnd exp1 exp2 -> prPrec i 2 (concatD [prt 3 exp1, doc (showString "&&"), prt 2 exp2])
    ENot exp -> prPrec i 6 (concatD [doc (showString "!"), prt 7 exp])
    ERel exp1 relop exp2 -> prPrec i 3 (concatD [prt 3 exp1, prt 0 relop, prt 4 exp2])
    EAdd exp1 addop exp2 -> prPrec i 4 (concatD [prt 4 exp1, prt 0 addop, prt 5 exp2])
    EMul exp1 mulop exp2 -> prPrec i 5 (concatD [prt 5 exp1, prt 0 mulop, prt 6 exp2])
    EApp exp appargs -> prPrec i 6 (concatD [prt 6 exp, doc (showString "("), prt 0 appargs, doc (showString ")")])
    EInt n -> prPrec i 7 (concatD [prt 0 n])
    EFloat d -> prPrec i 7 (concatD [prt 0 d])
    EBool boolean -> prPrec i 7 (concatD [prt 0 boolean])
    EError -> prPrec i 7 (concatD [doc (showString "error")])
    EVar id -> prPrec i 7 (concatD [prt 0 id])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print AddOp where
  prt i e = case e of
    Plus -> prPrec i 0 (concatD [doc (showString "+")])
    Minus -> prPrec i 0 (concatD [doc (showString "-")])

instance Print MulOp where
  prt i e = case e of
    Times -> prPrec i 0 (concatD [doc (showString "*")])
    Div -> prPrec i 0 (concatD [doc (showString "/")])

instance Print RelOp where
  prt i e = case e of
    LTC -> prPrec i 0 (concatD [doc (showString "<")])
    LEC -> prPrec i 0 (concatD [doc (showString "<=")])
    GTC -> prPrec i 0 (concatD [doc (showString ">")])
    GEC -> prPrec i 0 (concatD [doc (showString ">=")])
    EQC -> prPrec i 0 (concatD [doc (showString "==")])

instance Print Arg where
  prt i e = case e of
    Arg id -> prPrec i 0 (concatD [prt 0 id])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print AppArg where
  prt i e = case e of
    AppArg exp -> prPrec i 0 (concatD [prt 0 exp])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print Boolean where
  prt i e = case e of
    BTrue -> prPrec i 0 (concatD [doc (showString "True")])
    BFalse -> prPrec i 0 (concatD [doc (showString "False")])


