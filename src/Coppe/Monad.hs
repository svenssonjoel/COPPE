{- Monad.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Coppe.Monad (
  Coppe(..),
  getId,
  empty,
  operation,
  producer,
  build,
  coppeError,
  errorToString,
  ) where 

import Coppe.AST
import Control.Monad.Writer
import Control.Monad.State
import Control.Monad.Except
import Control.Monad.Trans.Except
import qualified  Control.Monad.Trans.State as S
import Coppe.Tinylang.AbsTinylang
import Coppe.Tinylang.EvalTinylang
import qualified Data.Map as Map

data CoppeError = CoppeError String

coppeError :: String -> Coppe a
coppeError str = throwError (CoppeError str)
errorToString (CoppeError str) = str

newtype Coppe a = Coppe (ExceptT CoppeError (StateT Integer (Writer Recipe)) a)
  deriving (Functor, Applicative, Monad, MonadState Integer, MonadWriter Recipe, MonadError CoppeError)

getId :: Coppe Integer
getId =
  do i <- get
     put (i + 1)
     return i
     
empty :: Coppe ()
empty = tell Empty


producer :: ( TensorRepr a)
          => Ingredient
          -> Dimensions
          -> Coppe (Tensor a)
producer op dim =
  do i <- getId
     let nom = "tensor" ++ show i
     tell $ Operation (hyperSet op [("name", valParam nom)])  
     let result =  mkTensor nom dim
     return result -- $ tensorReshape id {-(transform op)-}  result -- TODO: FIX

        
operation :: ( TensorRepr a)
          => Ingredient
          -> [Tensor a]
          -> Coppe (Tensor a)
operation _ [] = error "No inputs specified" 
operation op ts =
  let ids = map (\t -> (tensorId t)) ts
  in 
  do i <- getId
     let nom = "tensor" ++ show i
     tell $ Operation (hyperSet op [("input_layer", valParam ids), ("name", valParam nom)])

     let t_res = (transformDim op (map tensorDim ts))
     case t_res of
       Left (EvalError s) -> coppeError s
       Right val -> do
         let result_dim = fromValue val
         let result =  mkTensor nom result_dim
         return result 


transformDim :: Ingredient -> [Dimensions] -> Either EvalError Value
transformDim op i =
  let i' = toValue i
      (Ingredient _ a h _ exp) = op
      e = Map.empty
  in runEval h a e (evalApply exp i')


-- build :: Coppe a -> Either CoppeError Recipe
build (Coppe m) =
  let (a,w) = runWriter $ evalStateT (runExceptT m) 0
  in case a of
       Right _ -> Right w
       Left e  -> Left e 

