-- Experimentation
module Coppe
  where 

import Control.Monad.Writer
import Control.Monad.Trans.State

import CoppeAST

type Coppe a = StateT Integer (Writer Recipe) a

name :: Coppe Identifier
name =
  do i <- get
     put (i + 1)
     tell $ NamedIntermediate i
     return $ i

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
     return $ mkTensor i d

inputDouble :: [Integer] -> Coppe (Tensor Double) 
inputDouble d =
  do tell Input
     i <- getId
     return $ mkTensor i d
    
operation :: TensorRepr a
          => [Tensor a]
          -> Ingredient
          -> Hyperparameters
          -> Coppe (Tensor a)
operation [] _ _  = error "No inputs specified" 
operation ts op h =
  let ids = map (\t -> (tensorId t)) ts
      tensor = head ts
  in 
  do i <- getId 
     tell $ Operation op  (h {inputLayer = Just ids})
     tell $ NamedIntermediate i
     return $ mkTensor i (tensorDim tensor)

-- conv2D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
-- conv3D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
       
conv :: TensorRepr a =>  Hyperparameters -> Tensor a -> Coppe (Tensor a)
conv h t =
  if ok
  then
    do tens <-  operation [t] Conv h
       return $mkTensor (tensorId tens) (newDims ++ [f])
  else error $ "Bad Hyperparameters: " ++
       if nok
       then "one (or more) of kernelSize, filters or strides is not specified"
       else "input dimemsions " ++ show ndims ++ "\n" ++
            "kernelSize " ++ show ks ++ "\n" ++
            "strides " ++ show s ++ "\n" ++
            "filters " ++ show f ++ "\n"
  where
    -- what if only 1 dimension
    nok = kernelSize h == Nothing ||
          filters h == Nothing ||
          strides h == Nothing
    ok = not nok &&
         length ks == ndims - 1 &&
         length s  == ndims - 1
    Just (Dimensions ks) = kernelSize h
    Just (Filters f)     = filters h
    Just (Strides s)     = strides h
    ndims = length (tensorDim t)
    dims = take (ndims - 1) (tensorDim t)
    newDims = zipWith3 (\d k s -> (div (d - k + 2 * (k - 1)) (s + 1))) dims ks s
    
    
batchNormalize :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
batchNormalize h t = operation [t] BatchNormalize h

relu :: TensorRepr a => Tensor a -> Coppe (Tensor a)
relu t = operation [t] Relu emptyHyperparameters

-- Type instance for a ? 
add :: TensorRepr a => Tensor a -> Tensor a -> Coppe (Tensor a)
add a b =
  if ok 
  then operation [a,b] Add emptyHyperparameters
  else error $ "Mismatching tensor dimensions in Addition layer: " ++ show (tensorDim a) ++ "=/=" ++ show (tensorDim b) 
  where
    ok = length (tensorDim a) == length (tensorDim b) &&
         and (zipWith (==) (tensorDim a) (tensorDim b))
  --- Check dimensions match. 

rep :: Integer -> (Tensor a -> Coppe (Tensor a)) -> Tensor a -> Coppe (Tensor a)
rep 0 f t = return t
rep n f t =
   do t' <- f t
      rep (n - 1) f t'

skip :: Tensor a -> (Tensor a -> Coppe (Tensor b)) -> Coppe (Tensor a, Tensor b)
skip t f =
  do t' <- f t
     return (t, t')

build :: Coppe a -> Recipe
build m = execWriter $ evalStateT m 0

{-
 -  Messages that suggest that
    - add upsampling/downsampling layer
    - try using stride X
    - add padding

-}
testNetworkB =
  let convParams = emptyHyperparameters { kernelSize = Just (Dimensions [34,34])
                                        , strides = Just (Strides [1,1])
                                        , filters = Just (Filters 3)}
      addParams = emptyHyperparameters
  in
  do
    in_data <- inputFloat [32,32,3]
    out_data <- conv convParams in_data
                >>= batchNormalize emptyHyperparameters
                >>= relu
                >>= conv convParams
                >>= batchNormalize emptyHyperparameters
    add in_data out_data

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
    
                                  
    
  
