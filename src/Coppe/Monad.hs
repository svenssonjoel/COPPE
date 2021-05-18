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
     return $ tensorReshape id {-(transform op)-}  result -- TODO: FIX

        
operation :: ( TensorRepr a)
          => Ingredient
          -> [Tensor a]
          -> Coppe (Tensor a)
operation _ [] = error "No inputs specified" 
operation op ts =
  let ids = map (\t -> (tensorId t)) ts
      tensor = head ts
  in 
  do i <- getId
     let nom = "tensor" ++ show i
     -- tell $ Operation op (h {inputLayer = Just ids, name = Just nom})
     tell $ Operation (hyperSet op [("input_layer", valParam ids), ("name", valParam nom)])  
     let result =  mkTensor nom (tensorDim tensor)
     return $ tensorReshape id {-(transform op)-}  result -- TODO: FIX

build :: Coppe a -> Recipe
build (Coppe m) = execWriter $ evalStateT m 0
