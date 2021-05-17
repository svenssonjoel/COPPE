module Coppe.EvalTinylang where

import Coppe.TinyLang.AbsTinylang
import Coppe.AST

import Data.Maybe
import Data.Either
import qualified Data.Map as Map
import Control.Monad.State

{- Planning Tinylang

- A tinylang program can refer to any of parameters
  in the hyperparameter map by name. 
- A tinylang program can refer to any of the annotations
  in the annotation map by name.
- Should there be a way to tell those namespaces apart?

-} 

data EvalState = EvalState HyperMap Annotation (Map.Map String Value)
data EvalError = EvalError String
  deriving (Eq, Show)

type Eval a = State EvalState a

identToString (Ident s) = s

lookupBinding :: String -> Eval (Maybe Value)
lookupBinding s =
  do
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

-- Top level lambda is applied to the argument value
-- If that does not result in a value there program is "incorrect" 
evalTiny :: Exp -> Value -> Eval (Either EvalError Value)
evalTiny (EInt i) _ = return $ Right $ toValue i
evalTiny (EFloat d) _ = return $ Right $ toValue d
evalTiny (EVar i) _ =
  do res <- lookupBinding (identToString i)
     case res of
       Just v -> return $ Right v
       Nothing -> return $
                  Left $
                  EvalError $ "Ident " ++ identToString i ++ "is not present in environment, annotations or hyperparameters."
evalTiny (EAdd e1 op e2) _ = evalAdd op e1 e2
evalTiny (EMul e1 op e2) _ = evalMul op e1 e2
evalTiny (ERel e1 op e2) _ = evalRel op e1 e2
evalTiny e@(ELam _ _) args = evalLam e args
evalTiny (EApp e1 e2) _    =
  do v <- evalTiny e2 noArgs
     case v of
       Left err -> return $ Left err
       Right v ->  evalApp e1 v

evalApp :: Exp -> Value -> Eval (Either EvalError Value)
evalApp (EVar (Ident "length")) (ListVal l) = return $ Right $ toValue (length l)
evalApp (EVar (Ident "length")) _  = return $ Left $ EvalError "Argument to length is not a list."
evalApp (EVar (Ident "tail"))   (ListVal l) = return $ Right $ ListVal (tail l)
evalApp (EVar (Ident "tail"))   _ = return $ Left $ EvalError "Argument to rail is not a list."


addAllBindings :: [Exp] -> Value -> Eval (Either EvalError ())
addAllBindings [] (ListVal []) = return $ Right ()
addAllBindings (x:xs) (ListVal (v:vs)) =
  case x of
    (EVar (Ident s)) -> do addBinding s v
                           return $ Right ()
    _ -> return $ Left $ EvalError "Left hand side is not an identifier in binding"                       
                        
addAllBindings _ _  = return $ Left $ EvalError "Function application error"

 

evalLam :: Exp -> Value -> Eval (Either EvalError Value)
evalLam = undefined  

  
noArgs = ListVal []

evalAdd :: AddOp -> Exp -> Exp -> Eval (Either EvalError Value)
evalAdd aop e1 e2 =
  do v1 <- evalTiny e1 noArgs
     v2 <- evalTiny e2 noArgs
     let op :: Num a => a -> a -> a -- Make Haskell happy.. So needy!
         op = case aop of
                Plus -> (+)
                Minus -> (-)
     let r = case (v1,v2) of
               (Right (IntVal i1), Right (IntVal i2)) -> Right $ IntVal (op i1 i2)
               (Right (IntVal i1), Right (FloatVal f2)) -> Right $ FloatVal (op (fromIntegral i1) f2)
               (Right (FloatVal f1), Right (IntVal i2)) -> Right $ FloatVal (op f1 (fromIntegral i2))
               (_, _) -> Left $ EvalError "Arithmetic error"
     return r

evalMul :: MulOp -> Exp -> Exp -> Eval (Either EvalError Value)
evalMul mop e1 e2 =
  do v1 <- evalTiny e1 noArgs
     v2 <- evalTiny e2 noArgs
     let r = case mop of
               Times -> case (v1,v2) of
                          (Right (IntVal i1), Right (IntVal i2)) -> Right $ IntVal (i1 * i2)
                          (Right (IntVal i1), Right (FloatVal f2)) -> Right $ FloatVal ((fromIntegral i1) * f2)
                          (Right (FloatVal f1), Right (IntVal i2)) -> Right $ FloatVal (f1 * (fromIntegral i2))
                          (_, _) -> Left $ EvalError "Arithmetic error"
               Div -> case (v1,v2) of
                        (Right (IntVal i1), Right (IntVal i2)) -> Right $ IntVal (div i1 i2)
                        (Right (IntVal i1), Right (FloatVal f2)) -> Right $ FloatVal ((fromIntegral i1) / f2)
                        (Right (FloatVal f1), Right (IntVal i2)) -> Right $ FloatVal (f1 / (fromIntegral i2))
                        (_, _) -> Left $ EvalError "Arithmetic error"
     return r

evalRel :: RelOp -> Exp -> Exp -> Eval (Either EvalError Value)
evalRel rop e1 e2 =
  do v1 <- evalTiny e1 noArgs
     v2 <- evalTiny e2 noArgs
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
            
