{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module CoppeMonad (
  Coppe(..),
  getId,
  empty,
  inputFloat,
  inputDouble,
  operation,
  build
  ) where 

import CoppeAST
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

inputFloat :: [Integer] -> Coppe (Tensor Float) 
inputFloat d =
  do tell Input
     i <- getId
     return $ mkTensor ("tensor" ++ show i) d

inputDouble :: [Integer] -> Coppe (Tensor Double) 
inputDouble d =
  do tell Input
     i <- getId
     return $ mkTensor ("tensor" ++ show i) d
    
operation :: (Ingredient i, TensorRepr a)
          => i
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
     tell $ Operation (hyperSet op [("input_layer", toValue ids), ("name", toValue nom)])  
     let result =  mkTensor nom (tensorDim tensor)
     return $ tensorReshape (transform op) result

build :: Coppe a -> Recipe
build (Coppe m) = execWriter $ evalStateT m 0
