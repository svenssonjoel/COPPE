-- Experimentation
module Coppe
  where 

import Control.Monad.Writer
import Control.Monad.Trans.State

import Hyperparameters
import Tensor

data LayerOperation = Relu | Conv | BatchNormalize | Add
  deriving (Eq, Show)

type Name = String

data Net =
  Input 
  | Empty
  | NamedIntermediate Identifier
  | Operation LayerOperation Hyperparameters
  | Seq Net Net
  deriving (Eq, Show)

instance Semigroup Net where
  (<>) = Seq
  
instance Monoid Net where
  mempty = Empty
  mappend Empty a = a
  mappend a Empty = a
  mappend a b     = Seq a b

type Coppe a = StateT Integer (Writer Net) a

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
          -> LayerOperation
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
         
conv :: TensorRepr a =>  Hyperparameters -> Tensor a -> Coppe (Tensor a)
conv h t = operation [t] Conv h

batchNormalize :: TensorRepr a => Hyperparameters -> Tensor a -> Coppe (Tensor a)
batchNormalize h t = operation [t] BatchNormalize h

relu :: TensorRepr a => Tensor a -> Coppe (Tensor a)
relu t = operation [t] Relu emptyHyperparameters

-- Type instance for a ? 
add :: TensorRepr a => Tensor a -> Tensor a -> Coppe (Tensor a)
add a b =
  operation [a,b] Add emptyHyperparameters

rep :: Integer -> (Tensor a -> Coppe (Tensor a)) -> Tensor a -> Coppe (Tensor a)
rep 0 f t = return t
rep n f t =
   do t' <- f t
      rep (n - 1) f t'

skip :: Tensor a -> (Tensor a -> Coppe (Tensor b)) -> Coppe (Tensor a, Tensor b)
skip t f =
  do t' <- f t
     return (t, t')

build :: Coppe a -> Net
build m = execWriter $ evalStateT m 0

testNetworkB =
  let convParams = emptyHyperparameters {strides = Just (Strides [1,1])
                                        ,filters = Just (Filters 16)}
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
        

genYaml :: TensorRepr a => Coppe (Tensor a) -> String 
genYaml m = yaml $ build m 

  where
    yaml :: Net -> String
    yaml (Input)   = "input\n"
    yaml (Seq a b) = yaml a ++ yaml b
    yaml (NamedIntermediate i)  = "\t\tname:\n\t\tnom" ++ show i ++ "\n"
    yaml Empty   = ""
    yaml (Operation o h) = "\t- type:\n\t\t" ++ op o ++ "\n\thyperparams:\n" ++ hyper h

    op Add = "add"
    op Conv = "conv"
    op BatchNormalize = "batch_normalize"
    op Relu = "relu"

    hyper h = pStrides  (strides h) ++
              pFilters  (filters h) ++
              pVariance (variance h) ++
              pPadding  (padding h) ++
              pInit     (initialization h) ++
              pKernSize (kernelSize h) ++
              pInputs   (inputLayer h)

    pStrides Nothing = ""
    pStrides (Just (Strides xs)) = "\t\tstrides:\n" ++ (concatMap (\x -> "\t\t- " ++ show x ++ "\n") xs) ++ "\n"

    pFilters Nothing = ""
    pFilters (Just (Filters i)) = "\t\tfilters:\n\t\t" ++ show i ++ "\n"
    

    pVariance Nothing = ""
    pVariance (Just f) = "\t\tvariance:\n\t\t" ++ show f ++ "\n"
            
    pPadding Nothing = ""
    pPadding (Just Same) = "\t\tpadding:\n\t\tsame\n"

    pInit Nothing = ""
    pInit (Just Random) = "\t\tinit:\n\t\trandom\n"

    pKernSize Nothing = ""
    pKernSize (Just (Dimensions xs)) = "\t\tdimensions:\n" ++ (concatMap (\x -> "\t\t- " ++ show x ++ "\n") xs) ++ "\n"

    pInputs Nothing = ""
    pInputs (Just xs) = "\t\tinput_layer:\n" ++ (concatMap (\x -> "\t\t- " ++ "nom" ++ show x ++ "\n") xs) ++ "\n"
    
                                  
    
  
