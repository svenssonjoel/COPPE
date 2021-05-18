{- Prelude.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 


{- The refrigerator of ingredients -}


module Coppe.Prelude (
                  input
                , mkConv
                , mkRelu
                , mkBatchNorm
                , mkOptimizer
                -- Monad implementations
                , conv
                , batchNormalize
                , relu
                -- Arrow implementations
                , convA
                , batchNormalizeA
                , reluA
                ) where

import Coppe.AST
import Coppe.Monad
import Coppe.Arrow

import Data.Maybe
import qualified Data.Map as Map


{------------------------------------------------------------}
{- Functions -}


glorotUniform = NamedFun "glorot_uniform"

zeroes = NamedFun "Zeroes"

{------------------------------------------------------------}
{- Planning

-- conv2D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
-- conv3D :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)

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

-}

{----------------}
{- Input layers -} 

mkInput :: Ingredient
mkInput = Ingredient "input_layer" (Map.empty) (Map.empty) False "nothing" "nothing" 

{----------------}
{- Convolutions -}

-- Split out the dimensionality transform into a map
-- Map String (Dimension -> Dimension)

mkConv :: [Integer] -> [Integer] -> Integer -> Hyperparameters -> Ingredient
mkConv kernel_size strides filters hyps =
  let hyps' = Map.union (Map.fromList  [("kernel_size", valParam kernel_size),
                                        ("filters",     valParam filters),
                                        ("strides",     valParam strides)]) hm
  in Ingredient "conv" (Map.empty) hyps' True "nothing" "nothing" {- (convTransform kernel_size strides filters) -} 
  where
    hm = (Map.fromList hyps)

convTransform :: [Integer] -> [Integer] -> Integer -> Dimensions -> Dimensions
convTransform kernel_size strides filters tensorDim =
  if ok
  then newDims ++ [filters]
  else error "(conv) Incompatible hyperparameters and tensor dimensionality."
  where
    ndims = length tensorDim
    ok = length kernel_size == ndims - 1 && length strides  == ndims - 1
    dims = take (ndims-1) tensorDim
    newDims = zipWith3 (\d k s -> (div (d - k + 2 * (k - 1)) (s + 1)))
              dims
              kernel_size
              strides

convTransformSrc = unlines $ 
  ["fun dim -> ",
   "  let ndims = length dim in",
   "  let ok = length kernel_size == ndims - 1 && length strides == ndims - 1 in",
   "  let dims = take (ndims - 1) dim in",
   "  let newDims = zipWith3 (fun d k s -> ((d - k + 2 * (k - 1)) / (s + 1)))",
   "                dims ",
   "                kernel_size ",
   "                strides in",
   "  if ok then (extend newDims filters) else error" ]

              

{----------------}
{- RELU         -}


mkRelu :: Hyperparameters -> Ingredient
mkRelu hyps = Ingredient "relu" (Map.empty) (Map.fromList hyps) True "nothing" "nothing"

{-----------------------}
{- Batch normalization -}


mkBatchNorm :: Hyperparameters -> Ingredient
mkBatchNorm hyps = Ingredient "batch_normalize" (Map.empty) (Map.fromList hyps) True "nothing" "nothing"


{----------------}
{- Optimizer    -}

mkOptimizer :: Hyperparameters -> Ingredient
mkOptimizer hyps = Ingredient "optimizer" (Map.empty) (Map.fromList hyps) True "nothing" "nothing"

{----------------------------------------}
{-             MONAD STUFF              -}

input :: TensorRepr a => Dimensions -> Coppe (Tensor a)
input dims = producer mkInput dims

conv :: TensorRepr a => [Integer] -> [Integer] -> Integer -> Hyperparameters -> Tensor a -> Coppe (Tensor a)
conv ks ss f h t = operation (mkConv ks ss f h) [t]

batchNormalize :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
batchNormalize h t = operation (mkBatchNorm h) [t]

relu :: TensorRepr a => Tensor a -> Coppe (Tensor a)
relu t = operation (mkRelu emptyHyperparameters) [t]

{----------------------------------------}
{-             Arrow STUFF              -}

convA :: TensorRepr a => [Integer] -> [Integer] -> Integer -> Hyperparameters -> CoppeArrow (Tensor a) (Tensor a)
convA ks ss f hyps = coppeArrow (conv ks ss f hyps)

batchNormalizeA :: TensorRepr a => Hyperparameters -> CoppeArrow (Tensor a) (Tensor a)
batchNormalizeA hyps = coppeArrow (batchNormalize hyps)

reluA :: TensorRepr a =>  CoppeArrow (Tensor a) (Tensor a)
reluA = coppeArrow relu

