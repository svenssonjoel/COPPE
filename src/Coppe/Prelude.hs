{- Prelude.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 


{- The refrigerator of ingredients -}


module Coppe.Prelude (
                  input
                , mkConv
                , mkRelu
                , mkBatchNorm
                , mkAdd
                , mkOptimizer
                -- Monad implementations
                , conv
                , batchNormalize
                , relu
                , add
                , par
                -- Arrow implementations
                , convA
                , batchNormalizeA
                , reluA
                ) where

import Coppe.AST
import Coppe.Monad
import Coppe.Arrow
import Coppe.Tinylang

import Data.Maybe
import qualified Data.Map as Map


{------------------------------------------------------------}
{- TinyLang Functions -}

convTransform :: Exp 
convTransform = case parseTiny prg of
                  Left (ParseError s) -> error s
                  Right e -> e 
  where prg =
          unlines $ 
          ["fun dim -> ",
           "  let ndims = length(dim) in",
           "  let ok = length(kernel_size) == ndims - 1 && length(strides) == ndims - 1 in",
           "  let dims = take(ndims - 1, dim) in",
           "  let newDims = zipWith3(fun d k s -> ((d - k + 2 * (k - 1)) / (s + 1)),",
           "                dims, ",
           "                kernel_size, ",
           "                strides) in",
           "  if ok then extend(newDims,filters) else error(\"convTransform not ok!\")" ]


addTransform :: Exp
addTransform = case parseTiny prg of
                 Left (ParseError s) -> error s
                 Right e -> e
  where prg =
          unlines $
          ["fun d1 d2 -> ",
           "  let nd1 = length(d1) in",
           "  let nd2 = length(d2) in",
           "  let ndim_ok = nd1 == nd2 in",
           "  let ok_list = zipWith((fun a b -> a == b), d1, d2) in",
           "  if ndim_ok && ! (elem(False, ok_list)) then d1 else error(\"addTransform not ok!\")" ]

flattenTransform :: Exp
flattenTransform = case parseTiny prg of
                     Left (ParseError s) -> error s
                     Right e -> e
  where prg = "fun d1 -> prod(d1)"


tinyId :: Exp
tinyId = case parseTiny "fun a -> a" of
           Left (ParseError s) -> error s
           Right e -> e

tinyConst :: Int -> Exp
tinyConst n = case parseTiny ("fun a -> " ++ show n) of
                Left (ParseError s) -> error s
                Right e -> e

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
mkInput = Ingredient "input_layer" (Map.empty) (Map.empty) False tinyId  

{----------------}
{- Convolutions -}

-- Split out the dimensionality transform into a map
-- Map String (Dimension -> Dimension)

mkConv :: [Integer] -> [Integer] -> Integer -> Hyperparameters -> Ingredient
mkConv kernel_size strides filters hyps =
  let hyps' = Map.union (Map.fromList  [("kernel_size", valParam kernel_size),
                                        ("filters",     valParam filters),
                                        ("strides",     valParam strides)]) hm
  in Ingredient "conv" (Map.empty) hyps' True convTransform 
  where
    hm = (Map.fromList hyps)

{-----------}
{- POOLING -} 

mkPooling :: [Integer] -> [Integer] -> Hyperparameters -> Ingredient
mkPooling pool_size strides = undefined -- I dont know what to do 
         
{----------------}
{- RELU         -}


mkRelu :: Hyperparameters -> Ingredient
mkRelu hyps = Ingredient "relu" (Map.empty) (Map.fromList hyps) True tinyId  

{-----------------------}
{- Batch normalization -}


mkBatchNorm :: Hyperparameters -> Ingredient
mkBatchNorm hyps = Ingredient "batch_normalize" (Map.empty) (Map.fromList hyps) True tinyId  

{-------}
{- Add -}

mkAdd :: Ingredient
mkAdd = Ingredient "add" (Map.empty) (Map.empty) False addTransform


{-----------}
{- FLATTEN -}

mkFlatten :: Hyperparameters -> Ingredient
mkFlatten hyps = Ingredient "flatten" (Map.empty) (Map.fromList hyps) False flattenTransform


{----------------}
{- Optimizer    -}

mkOptimizer :: Hyperparameters -> Ingredient
mkOptimizer hyps = Ingredient "optimizer" (Map.empty) (Map.fromList hyps) True tinyId

{----------------------------------------}
{-             MONAD STUFF              -}

input :: TensorRepr a => Tensor a -> Coppe (Tensor a)
input t = producer mkInput (tensorDim t)

conv :: TensorRepr a => [Integer] -> [Integer] -> Integer -> Hyperparameters -> Tensor a -> Coppe (Tensor a)
conv ks ss f h t = operation (mkConv ks ss f h) [t]

batchNormalize :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
batchNormalize h t = operation (mkBatchNorm h) [t]

relu :: TensorRepr a => Tensor a -> Coppe (Tensor a)
relu t = operation (mkRelu emptyHyperparameters) [t]

add :: TensorRepr a => Tensor a -> Tensor a -> Coppe (Tensor a)
add t1 t2 = operation (mkAdd) [t1,t2]


{-Combinators-}

par :: (TensorRepr a, TensorRepr b, TensorRepr c)
  =>  (Tensor a -> Coppe (Tensor b)) -> (Tensor a -> Coppe (Tensor c)) -> Tensor a -> Coppe (Tensor b, Tensor c)
par f g t =
  do a <- f t
     b <- g t
     return (a,b)



{----------------------------------------}
{-             Arrow STUFF              -}

convA :: TensorRepr a => [Integer] -> [Integer] -> Integer -> Hyperparameters -> CoppeArrow (Tensor a) (Tensor a)
convA ks ss f hyps = coppeArrow (conv ks ss f hyps)

batchNormalizeA :: TensorRepr a => Hyperparameters -> CoppeArrow (Tensor a) (Tensor a)
batchNormalizeA hyps = coppeArrow (batchNormalize hyps)

reluA :: TensorRepr a =>  CoppeArrow (Tensor a) (Tensor a)
reluA = coppeArrow relu

-- The arrow library has some interesting ones already 
