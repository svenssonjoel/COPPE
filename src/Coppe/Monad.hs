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
  build
  ) where 

import Coppe.AST
import Control.Monad.Writer
import Control.Monad.State
import qualified  Control.Monad.Trans.State as S
import Coppe.Tinylang.AbsTinylang
import Coppe.Tinylang.EvalTinylang
import qualified Data.Map as Map

newtype Coppe a = Coppe (StateT Integer (Writer Recipe) a)
  deriving (Functor, Applicative, Monad, MonadState Integer, MonadWriter Recipe)

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

     let result_dim = (transformDim op (map tensorDim ts)) 

     -- Evaluate for the side effect of error 
     (result_dim `seq` return ()) 
       
     let result =  mkTensor nom result_dim
     return result -- id {-(transform op)-}  result -- TODO: FIX


transformDim :: Ingredient -> [Dimensions] -> Dimensions
transformDim op i =
  let i' = toValue i
      (Ingredient _ a h _ exp) = op
      e = Map.empty
  in  case (runEval h a e (evalApply exp i')) of
        Left (EvalError s) -> error $ "Error evaluating transformation function\n" ++ " " ++ s ++ "\n"
        Right l@(ListVal _) -> error $ show l -- (fromValue l)


build :: Coppe a -> Recipe
build (Coppe m) = execWriter $ evalStateT m 0
