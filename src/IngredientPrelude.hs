

{- The refrigerator of ingredients -} 


module IngredientPrelude (
                  mkConv
                , mkRelu
                , mkBatchNorm
                , mkOptimizer
                ) where



import CoppeAST
import Data.Maybe
import qualified Data.Map as Map


{----------------}
{- Convolutions -}

data Conv = Conv HyperMap Annotation 

instance Ingredient Conv where
  name _ = "conv"
  annotation (Conv h a) = a
  annotate s v (Conv h a) = Conv h (Map.insert s v a)
  create hyps = Conv (Map.fromList hyps) (Map.empty)
  hyperSet (Conv h a) h' = Conv (Map.union (Map.fromList h') h) a
  hyperGet (Conv h _) = h
  transform a tensorDim = if nok
                     then error $ "(conv) Missing hyperparameters: kernel-size, filters and strides must be specified."
                     else if ok
                          then newDims ++ [f]
                          else error "(conv) Incompatible hyperparameters and tensor dimensionality."
                    
    where hm = hyperGet a
          kernel_size = Map.lookup "kernel-size" hm
          filters     = Map.lookup "filters" hm
          strides     = Map.lookup "strides" hm
          nok = kernel_size == Nothing || filters == Nothing || strides == Nothing
          (Just lv) = kernel_size -- kernel size must be a list
          (Just fv)  = filters     -- Filters must be an IntVal
          (Just sv)  = strides     -- Strides must be an IntVal
          ks =  dimValToList lv
          s  =  strideValToList sv
          f  =  filterValToInt fv
          ok = length ks == ndims - 1 && length s == ndims - 1
          ndims = length tensorDim
          dims = take (ndims-1) tensorDim
          newDims = zipWith3 (\d k s -> (div (d - k + 2 * (k - 1)) (s + 1)))
                    dims
                    ks
                    s

          
          

instance Show Conv where
  show = name 

mkConv :: Hyperparameters -> Conv
mkConv = create


{----------------}
{- RELU         -}



data Relu = Relu HyperMap Annotation

instance Ingredient Relu where
  name _ = "relu"
  annotation (Relu h a) = a
  annotate s v (Relu h a) = Relu h (Map.insert s v a)
  create hyps = Relu (Map.fromList hyps) (Map.empty)
  hyperSet (Relu h a) h' = Relu (Map.union (Map.fromList h') h) a
  hyperGet (Relu h _) = h
  transform a = id -- identity transformation of tensor shape

instance Show Relu where
  show = name

mkRelu :: Hyperparameters -> Relu
mkRelu = create


{-----------------------}
{- Batch normalization -}


data BatchNorm = BatchNorm HyperMap Annotation

instance Ingredient BatchNorm where
  name _ = "batch_normalize"
  annotation (BatchNorm h a) = a
  annotate s v (BatchNorm h a) = BatchNorm h (Map.insert s v a)
  create hyps = BatchNorm (Map.fromList hyps) (Map.empty)
  hyperSet (BatchNorm h a) h' = BatchNorm (Map.union (Map.fromList h') h) a
  hyperGet (BatchNorm h _) = h
  transform a = id

instance Show BatchNorm where
  show = name

mkBatchNorm :: Hyperparameters -> BatchNorm 
mkBatchNorm = create

{----------------}
{- Optimizer    -}


data Optimizer = Optimizer HyperMap Annotation

instance Ingredient Optimizer where
  name _  = "Optimizer"
  annotation (Optimizer h a) = a
  annotate s v (Optimizer h a) = Optimizer h (Map.insert s v a)
  create hyps = Optimizer (Map.fromList hyps) (Map.empty)
  hyperSet (Optimizer h a) h' = Optimizer (Map.union (Map.fromList h') h) a
  hyperGet (Optimizer h _) = h
  transform a = id

mkOptimizer :: Hyperparameters -> Optimizer
mkOptimizer = create
