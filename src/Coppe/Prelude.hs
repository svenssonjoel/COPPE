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
                , flatten
                , dropout
                , softmax
                , maxPooling2D
                , dense
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

-- TODO: Implement padding. 

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

-- Assume "Valid" padding
-- Must implement "same" and "valid"

-- Dilation could be present in the hyperparameters

maxPooling2DTransform :: Exp
maxPooling2DTransform =
  case parseTiny prg of
                  Left (ParseError s) -> error s
                  Right e -> e 
  where prg =
          unlines $ 
          ["fun dim -> ",
           "  let pw = index(0, pool_size)",
           "  let ph = index(1, pool_size)",
           "  let sw = index(0, strides)",
           "  let sh = index(1, strides)", 
           "  let dw = index(0, dilation)",
           "  let dh = index(1, dilation)",
           "  let w  = index(0, dim)",
           "  let h  = index(1, dim)",
           "  in list( floor( (((w * (-dw * (pw - 1)) - 1) / sw))) + 1,",
           "           floor( (((h * (-dh * (ph - 1)) - 1) / sh))) + 1)"]


--- floor(((H * ( -dilation[0] * (pool_size[0] -1 )) -1 ) / stride[0]) + 1)
--- floor(((W * ( -dilation[1] * (pool_size[1] -1 )) -1 ) / stride[1]) + 1)

-- https://pytorch.org/docs/stable/generated/torch.nn.MaxPool2d.html

maxPooling2DTransformSame :: Exp
maxPooling2DTransformSame = tinyId

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


denseTransform :: Exp
denseTransform = case parseTiny prg of
                 Left (ParseError s) -> error s
                 Right e -> e
  where prg =
          unlines $
          ["fun dim -> nunits"]


dropoutTransform :: Exp
dropoutTransform = tinyId

softmaxTransform :: Exp
softmaxTransform = tinyId

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

{---------------}
{- Dense Layer -}

mkDense :: Integer -> Hyperparameters -> Ingredient
mkDense nunits hyps = Ingredient "dense" (Map.empty) hyps' True denseTransform
  where hyps' = Map.union (Map.fromList [("nunits", valParam nunits)]) hm
        hm    = Map.fromList hyps

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


{-----------}
{- Dropout -}

mkDropout :: Double -> Hyperparameters -> Ingredient
mkDropout rate hyps =
  let hyps' = Map.union ( Map.fromList [("rate", valParam rate)]) hm
      hm   = Map.fromList hyps
  in Ingredient "dropout" (Map.empty) hyps' False dropoutTransform

{-----------}
{- Softmax -}
mkSoftmax :: Hyperparameters -> Ingredient
mkSoftmax hyps = Ingredient "softmax" (Map.empty) (Map.fromList hyps) False softmaxTransform

{-------------}
{- Pooling2D -}
mkMaxPooling2D :: [Integer] -> Hyperparameters -> Ingredient
mkMaxPooling2D pool_size hyps
  = Ingredient "pooling2d" (Map.empty) (Map.union defaultHyps hyps') False maxPooling2DTransform
  where defaultHyps = Map.fromList [("dilation", ValParam $ ListVal [IntVal 0, IntVal 0])
                                   ,("strides" , ValParam $ ListVal [IntVal 1, IntVal 1])
                                   ,("pool_size", valParam pool_size)]
        hyps' = Map.fromList hyps
                                                      


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

flatten :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
flatten h t1 = operation (mkFlatten h) [t1]

dropout :: TensorRepr a => Double -> Hyperparameters -> Tensor a -> Coppe (Tensor a)
dropout d h t1 = operation (mkDropout d h) [t1]

softmax :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
softmax h t1 = operation (mkSoftmax h) [t1]

maxPooling2D :: TensorRepr a => [Integer] -> Hyperparameters -> Tensor a -> Coppe (Tensor a)
maxPooling2D pool_size h t1 = operation (mkMaxPooling2D pool_size h) [t1]

dense :: TensorRepr a => Integer -> Hyperparameters -> Tensor a -> Coppe (Tensor a)
dense nunits h t1 = operation (mkDense nunits h) [t1]

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
