module Coppe.Tinylang.EvalTinylang where

import Coppe.Tinylang.AbsTinylang
import Coppe.Tinylang.LexTinylang
import Coppe.Tinylang.ParTinylang
import Coppe.Tinylang.PrintTinylang
import Coppe.Tinylang.ErrM

import Coppe.AST

import Data.Maybe
import Data.Either
import qualified Data.Map as Map
import Control.Monad.State
import MonadUtils

data ParseError = ParseError String

parseTiny :: String -> Either ParseError Exp
parseTiny s =
  let ts = myLexer s
  in case pExp ts of
       Bad s -> Left $ ParseError s
       Ok  e -> Right e 


{- Planning Tinylang

- A tinylang program can refer to any of parameters
  in the hyperparameter map by name. 
- A tinylang program can refer to any of the annotations
  in the annotation map by name.
- Should there be a way to tell those namespaces apart?

TODOs

- add some way to translate values to strings for use in error messages.
- Odd function application syntax `f (arg1, ... , argn)`, fine by me but odd. see
  what can be done.

-} 

data EvalState = EvalState HyperMap Annotation (Map.Map String Value)
data EvalError = EvalError String
  deriving (Eq, Show)

type Eval a = State EvalState a

identToString (Ident s) = s
argToString   (ArgIdent (Ident s)) = s 

builtIn :: [String]
builtIn = ["length",
           "tail",
           "take",
           "extend",
           "zipWith3",
           "zipWith",
           "elem",
           "error",
           "elem",
           "floor",
           "ceil",
           "index"]

-- LookupBinding ignores the FunParams that may be in a hypermap.
lookupBinding :: String -> Eval (Maybe Value)
lookupBinding s =
    if (s `elem` builtIn)
      then return $ Just $ StringVal s
      else do
        (EvalState h a e) <- get
        let r = case Map.lookup s h of
                  Just (ValParam v) -> Just v
                  _ -> case Map.lookup s a of
                         Just v -> Just v
                         _ -> case Map.lookup s e of
                                Just v -> Just v
                                _ -> Nothing
        return r

addBinding :: String -> Value -> Eval ()
addBinding s v =
  do (EvalState h a e) <- get
     let e' = Map.insert s v e
     put (EvalState h a e')

runEval :: HyperMap -> Annotation -> Map.Map String Value -> Eval (Either EvalError Value) -> (Either EvalError Value)
runEval h a e eval =
  let estate = EvalState h a e
  in evalState eval estate 

-- Top level lambda is applied to the argument value
evalApply :: Exp -> Value -> Eval (Either EvalError Value)
evalApply e v =
  do f <- evalTiny e 
     case f of
       Left err -> return $ Left err
       Right (CloVal f args h a env) ->
         do put (EvalState h a env) 
            addAllBindings args v
            evalTiny f
       Right _ -> return $ Left $ EvalError "evalApply: Not a function"
           

-----------------------------
-- EVALUATE A TINY PROGRAM --

evalTiny :: Exp -> Eval (Either EvalError Value)
evalTiny (ELet (EVar (Ident name)) ev e) =
          do
            val <- evalTiny ev
            case val of
              Right v -> do addBinding name v
                            evalTiny e
              Left err -> return $ Left err 
           


evalTiny (EInt i)    = return $ Right $ toValue i
evalTiny (EFloat d)  = return $ Right $ toValue d
evalTiny (EBool BTrue)   = return $ Right $ toValue True
evalTiny (EBool BFalse)  = return $ Right $ toValue False
evalTiny (EString s)     = return $ Right $ toValue s
evalTiny (EVar i)    =
  do res <- lookupBinding (identToString i)
     ( EvalState h m e) <- get
     case res of
       Just v -> return $ Right v
       Nothing -> if (identToString i) `elem` builtIn
                  then return $ Right (StringVal (identToString i))
                  else return $
                       Left $
                       EvalError $ "Ident " ++ identToString i ++ " is not present in environment, annotations or hyperparameters: " ++ show e
                       
evalTiny (EAdd e1 op e2) = evalAdd op e1 e2
evalTiny (EMul e1 op e2) = evalMul op e1 e2
evalTiny (ERel e1 op e2) = evalRel op e1 e2
evalTiny (EOr  e1 e2)    = do a <- evalTiny e1
                              b <- evalTiny e2
                              case (a,b) of
                                (Right (BoolVal a'), Right (BoolVal b')) -> return $ Right (BoolVal (a' || b'))
                                (x,y) -> return $ Left $ EvalError $ "Not a boolean used in ||  ( " ++ show x ++ " || " ++ show y ++ ")"
evalTiny (EAnd  e1 e2)    = do a <- evalTiny e1
                               b <- evalTiny e2
                               case (a,b) of
                                 (Right (BoolVal a'), Right (BoolVal b')) -> return $ Right (BoolVal (a' && b'))
                                 (x,y) -> return $ Left $ EvalError $ "Not a boolean used in &&  ( " ++ show x ++ " && " ++ show y ++ ")"
evalTiny (ENot e1) = do a <- evalTiny e1
                        case a of
                          (Right (BoolVal a')) -> return $ Right (BoolVal (not a'))
                          x -> return $ Left $ EvalError $ "not a boolean used in !  ( " ++ show x ++ ")"
                                                                                                   
evalTiny (ELam as e)     = evalLam as e
-- evalTiny EError          = return $ Left $ EvalError "Program finishes in error"
evalTiny (EIf  e1 e2 e3) =
  do
    cond <- evalTiny e1
    case cond of
      (Right (BoolVal True))  -> evalTiny e2
      (Right (BoolVal False)) -> evalTiny e3
      (Left (EvalError s))    -> return $ Left $ EvalError s
evalTiny (EApp e1 e2)    =
  do args <- evalArgs e2
     f <- evalTiny e1
     case (f,args) of
       (Right f, Right v) -> evalApp f v
       (Left e, _)        -> return $ Left e
       (_, Left e)        -> return $ Left e
  
evalTiny x = error $ "Not implemented: " ++ show x

------------------------
-- EVALUATE ARGUMENTS -- 


evalArgs :: [AppArg] -> Eval (Either EvalError Value)
evalArgs (es) =
  do
    res <- mapM (\(AppArgExp e) -> evalTiny e) es
    let (ls,rs) = partitionEithers res
    case ls of
      [] -> return $ Right $ ListVal $ rights res
      (x:_) -> return $ Left x 


--------------------------
-- EVALUATE APPLICATION --

evalApp :: Value -> Value -> Eval (Either EvalError Value)
evalApp (StringVal "length")  (ListVal [(ListVal l)])
  = return $ Right $ toValue (length l)

evalApp (StringVal "length")  _
  = return $ Left $ EvalError "Argument to length is not a list."

evalApp (StringVal "floor") (FloatVal f)
  = return $ Right $ toValue ((floor f) :: Integer)
evalApp (StringVal "floor")  _
  = return $ Left $ EvalError "Argument to floor is not a float."

evalApp (StringVal "ceil") (FloatVal f)
  = return $ Right $ toValue ((ceiling f) :: Integer)
evalApp (StringVal "ceil")  _
  = return $ Left $ EvalError "Argument to ceil is not a float."

evalApp (StringVal "tail") (ListVal [(ListVal l)])
  = return $ Right $ ListVal (tail l)
evalApp (StringVal "tail") _
  = return $ Left $ EvalError "Argument to tail is not a list."

evalApp (StringVal "take")   (ListVal [IntVal n, ListVal l])
  = return $ Right $ ListVal (take (fromInteger n) l)
evalApp (StringVal "take") a
  = return $ Left $ EvalError $ "Argument to take incorrect: " ++ show a

evalApp (StringVal "index") (ListVal [IntVal n, ListVal l])
  = return $ Right $ l !! (fromInteger n)
evalApp (StringVal "index") a
  = return $ Left $ EvalError $ "Argument to index incorrect: " ++ show a
  
evalApp (StringVal "extend") (ListVal [ListVal l1, a2])
  = return $ Right $ ListVal (l1 ++ [a2])
evalApp (StringVal "extend") a
  = return $ Left $ EvalError $ "Argument to extend incorrect: " ++ show a

evalApp (StringVal "elem") (ListVal [v, (ListVal l)])
  = return $ Right $ toValue (v `elem` l)
evalApp (StringVal "elem") x
  = return $ Left $ EvalError $ "Argument to elem incorrect: " ++ show x

evalApp (StringVal "zipWith") (ListVal [closure, ListVal l1, ListVal l2])
  = do
  res <- evalZipWith closure (ListVal l1) (ListVal l2)
  let (ls,rs) = partitionEithers res
  case ls of
    [] -> return $ Right $ ListVal rs
    (x:_) -> return $ Left x

evalApp (StringVal "zipWith3") (ListVal [closure, ListVal l1, ListVal l2, ListVal l3])
  = do 
      res <- evalZipWith3 closure (ListVal l1) (ListVal l2) (ListVal l3)
      let (ls,rs) = partitionEithers res
      case ls of
        [] -> return $ Right $ ListVal rs
        (x:_) -> return $ Left x

evalApp (StringVal "zipWith3") _
  = return $ Left $ EvalError "Argument to zipWith3 incorrect."

evalApp (StringVal "error") (ListVal [])
  = return $ Left $ EvalError $ "Tinylang program ended in error: unknown error "

evalApp (StringVal "error") (ListVal [(StringVal s)])
  = return $ Left $ EvalError $ "Tinylang program ended in error: " ++ s

evalApp (StringVal "error") x
  = return $ Left $ EvalError $ "Tinylang program ended in error: " ++ show x

evalApp (StringVal x) _
  = return $ Left $ EvalError $ "Unknown function: " ++ x

evalApp _ _
  = return $ Left $ EvalError "Unknown function."
-- TODO: Closure application


evalZipWith (CloVal f args h a e) (ListVal ls1) (ListVal ls2) =
  zipWithM body ls1 ls2
  where
    body x y =
      local $
      do put $ EvalState h a e
         addAllBindings args (ListVal [x, y])
         evalTiny f


evalZipWith3 (CloVal f args h a e) (ListVal ls1) (ListVal ls2) (ListVal ls3) =
  zipWith3M body ls1 ls2 ls3
  where
    body x y z =
      local $
      do put $ EvalState h a e
         addAllBindings args (ListVal [x, y, z])
         evalTiny f

local :: Eval (Either EvalError a) -> Eval (Either EvalError a)
local e =
  do old <- get
     a <- e
     put old
     return a

addAllBindings :: [Arg] -> Value -> Eval (Either EvalError ())
addAllBindings [] (ListVal []) = return $ Right ()
addAllBindings (x:xs) (ListVal (v:vs)) =
  case x of
    (ArgIdent i) -> do addBinding (identToString i) v
                       addAllBindings xs (ListVal vs)
                        
addAllBindings _ _  = return $ Left $ EvalError "Function application error"

-- Create and return a closure Value
evalLam :: [Arg] -> Exp -> Eval (Either EvalError Value)
evalLam as e = do 
  EvalState h a env <- get
  return $ Right $ CloVal e as h a env
  
noArgs = ListVal []

evalAdd :: AddOp -> Exp -> Exp -> Eval (Either EvalError Value)
evalAdd aop e1 e2 =
  do v1 <- evalTiny e1
     v2 <- evalTiny e2
     let op :: Num a => a -> a -> a -- Make Haskell happy.. So needy!
         op = case aop of
                Plus -> (+)
                Minus -> (-)
         opstr = case aop of
                   Plus -> " + "
                   Minus -> " - "
     let r = case (v1,v2) of
               (Right (IntVal i1), Right (IntVal i2)) -> Right $ IntVal (op i1 i2)
               (Right (IntVal i1), Right (FloatVal f2)) -> Right $ FloatVal (op (fromIntegral i1) f2)
               (Right (FloatVal f1), Right (IntVal i2)) -> Right $ FloatVal (op f1 (fromIntegral i2))
               (x, y) -> Left $ EvalError $ "Arithmetic error: " ++ show x ++ opstr ++ show y
     return r

-- Division always results in a float value
evalMul :: MulOp -> Exp -> Exp -> Eval (Either EvalError Value)
evalMul mop e1 e2 =
  do v1 <- evalTiny e1
     v2 <- evalTiny e2
     let r = case mop of
               Times -> case (v1,v2) of
                          (Right (IntVal i1), Right (IntVal i2)) -> Right $ IntVal (i1 * i2)
                          (Right (IntVal i1), Right (FloatVal f2)) -> Right $ FloatVal ((fromIntegral i1) * f2)
                          (Right (FloatVal f1), Right (IntVal i2)) -> Right $ FloatVal (f1 * (fromIntegral i2))
                          (x, y) -> Left $ EvalError $ "Arithmetic error: " ++ show x ++ " * " ++ show y
               Div -> case (v1,v2) of
                        (Right (IntVal i1), Right (IntVal i2)) -> Right $ FloatVal ((fromIntegral i1) / (fromIntegral i2))
                        (Right (IntVal i1), Right (FloatVal f2)) -> Right $ FloatVal ((fromIntegral i1) / f2)
                        (Right (FloatVal f1), Right (IntVal i2)) -> Right $ FloatVal (f1 / (fromIntegral i2))
                        (x, y) -> Left $ EvalError $ "Arithmetic error: " ++ show x ++ " / " ++ show y
     return r

evalRel :: RelOp -> Exp -> Exp -> Eval (Either EvalError Value)
evalRel rop e1 e2 =
  do v1 <- evalTiny e1
     v2 <- evalTiny e2
     let op :: (Eq a, Ord a) => a -> a -> Bool
         op = case rop of
                LTC -> (<)
                LEC -> (<=)
                GTC -> (>)
                GEC -> (>=)
                EQC -> (==)
     let r = case (v1,v2) of
               (Right (IntVal i1), Right (IntVal i2)) -> Right $ BoolVal (op i1 i2)
               (Right (IntVal i1), Right (FloatVal f2)) -> Right $ BoolVal (op (fromIntegral i1) f2)
               (Right (FloatVal f1), Right (IntVal i2)) -> Right $ BoolVal (op f1 (fromIntegral i2))
               (_, _) -> Left $ EvalError "Arithmetic error"
     return r
            
