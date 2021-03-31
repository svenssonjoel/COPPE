-- Experimentation
module Coppe (
  module CoppeAST
  , module IngredientPrelude

  , build
  , conv
  , batchNormalize
  , relu
  , inputFloat
  )
  where 

import Control.Monad.Writer
import Control.Monad.Trans.State

import CoppeAST
import IngredientPrelude

type Coppe a = StateT Integer (Writer Recipe) a

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
     tell $ Operation (hyperSet op [("inputLayer", toValue ids), ("name", toValue nom)])  
     let result =  mkTensor nom (tensorDim tensor)
     return $ tensorReshape (transform op) result

-- conv2D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
-- conv3D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
       
conv :: TensorRepr a =>  Hyperparameters -> Tensor a -> Coppe (Tensor a)
conv h t = operation (mkConv h) [t]
        
  
batchNormalize :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
batchNormalize h t = operation (mkBatchNorm h) [t]

relu :: TensorRepr a => Tensor a -> Coppe (Tensor a)
relu t = operation (mkRelu emptyHyperparameters) [t]

-- Type instance for a ? 
-- add :: TensorRepr a => Tensor a -> Tensor a -> Coppe (Tensor a)
-- add a b =
--   if ok 
--   then operation [a,b] Add emptyHyperparameters
--   else error $ "Mismatching tensor dimensions in Addition layer: " ++ show (tensorDim a) ++ "=/=" ++ show (tensorDim b) 
--   where
--     ok = length (tensorDim a) == length (tensorDim b) &&
--          and (zipWith (==) (tensorDim a) (tensorDim b))
--   --- Check dimensions match. 

-- rep :: Integer -> (Tensor a -> Coppe (Tensor a)) -> Tensor a -> Coppe (Tensor a)
-- rep 0 f t = return t
-- rep n f t =
--    do t' <- f t
--       rep (n - 1) f t'

-- skip :: Tensor a -> (Tensor a -> Coppe (Tensor b)) -> Coppe (Tensor a, Tensor b)
-- skip t f =
--   do t' <- f t
--      return (t, t')

build :: Coppe a -> Recipe
build m = execWriter $ evalStateT m 0

{-
 -  Messages that suggest that
    - add upsampling/downsampling layer
    - try using stride X
    - add padding
-}


-- testSkip =
--   let convParams = emptyHyperparameters {strides = Just (Strides [1,1])
--                                         ,filters = Just (Filters 16)}
--       addParams = emptyHyperparameters
--   in
--   do input_data <- name 
--      conv convParams  
--      batchNormalize emptyHyperparameters
--      relu
--      (before, after) <- skip $ rep 10 $ conv convParams
--      add before after
--      batchNormalize emptyHyperparameters
--      bn_out <- name
--      add input_data bn_out
    
                                  
    
  
