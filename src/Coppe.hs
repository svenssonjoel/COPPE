-- Experimentation
module Coppe
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
          => [Tensor a]
          -> i
          -> Coppe (Tensor a)
operation [] _  = error "No inputs specified" 
operation ts op =
  let ids = map (\t -> (tensorId t)) ts
      tensor = head ts
  in 
  do i <- getId
     let nom = "tensor" ++ show i
     -- tell $ Operation op (h {inputLayer = Just ids, name = Just nom})
     tell $ Operation (hyperSet op [("inputLayer", toValue ids), ("name", toValue nom)])  
     return $ mkTensor nom (tensorDim tensor)

-- conv2D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
-- conv3D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
       
conv :: TensorRepr a =>  Hyperparameters -> Tensor a -> Coppe (Tensor a)
conv h t =
  let c = mkConv h
  in do operation [t] c
        return $ tensorReshape (transform c) t
  
batchNormalize :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
batchNormalize h t = operation [t] $ mkBatchNorm h

relu :: TensorRepr a => Tensor a -> Coppe (Tensor a)
relu t = operation [t] $ mkRelu emptyHyperparameters

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


testNetworkB =
  let convParams = [("kernelSize", toValue [34,34 :: Int])
                   ,("strides", toValue [1,1 :: Int])
                   ,("filters", toValue (3 :: Int))]
      addParams = emptyHyperparameters
  in
  do
    in_data <- inputFloat [32,32,3]
    out_data <- conv convParams in_data
                >>= batchNormalize emptyHyperparameters
                >>= relu
                >>= conv convParams
                >>= batchNormalize emptyHyperparameters
    return out_data 

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
    
                                  
    
  
