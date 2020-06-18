
-- Experimentation
module Coppe
  where 

import Control.Monad.Writer
import Control.Monad.Trans.State

import Hyperparameters

data LayerOperation = Relu | Conv | BatchNormalize | Add
  deriving (Eq, Show)

type Name = String

data Recipe =
  Input
  | Empty
  | NamedIntermediate Identifier
  | Operation LayerOperation Hyperparameters
  | Seq Recipe Recipe
  deriving (Eq, Show)

instance Semigroup Recipe where
  (<>) = Seq
  
instance Monoid Recipe where
  mempty = Empty
  mappend Empty a = a
  mappend a Empty = a
  mappend a b     = Seq a b

type Coppe a = StateT Integer (Writer Recipe) a

name :: Coppe Identifier
name =
  do i <- get
     put (i + 1)
     tell $ NamedIntermediate (Identifier i)
     return $ Identifier i
     
empty :: Coppe ()
empty = tell Empty

input :: Coppe ()
input = tell Input

operation :: LayerOperation -> Hyperparameters -> Coppe ()
operation op h = tell $ Operation op h

conv :: Hyperparameters -> Coppe ()
conv h = operation Conv h

batchNormalize :: Hyperparameters -> Coppe ()
batchNormalize h = operation BatchNormalize h

relu :: Coppe ()
relu = operation Relu emptyHyperparameters

add :: Identifier -> Identifier -> Coppe ()
add a b = operation Add (emptyHyperparameters {inputLayer = Just [a, b]})

test :: Coppe a -> Coppe (a, Recipe)
test = listen

rep :: Integer -> Coppe () -> Coppe ()
rep 0 m = empty
rep n m = m >> rep (n-1) m

skip :: Coppe () -> Coppe (Identifier,Identifier)
skip m =
  do intermediate <- name
     m
     result <- name
     return (intermediate, result)


build :: Coppe a -> Recipe
build m = execWriter $ evalStateT m 0

testNetwork =
  let convParams = emptyHyperparameters {strides = Just (Strides [1,1])
                                        ,filters = Just (Filters 16)}
      addParams = emptyHyperparameters
  in
  do input_data <- name 
     conv convParams  
     batchNormalize emptyHyperparameters
     relu
     conv convParams
     batchNormalize emptyHyperparameters
     bn_out <- name
     add input_data bn_out


testSkip =
  let convParams = emptyHyperparameters {strides = Just (Strides [1,1])
                                        ,filters = Just (Filters 16)}
      addParams = emptyHyperparameters
  in
  do input_data <- name 
     conv convParams  
     batchNormalize emptyHyperparameters
     relu
     (before, after) <- skip $ rep 10 $ conv convParams
     add before after
     batchNormalize emptyHyperparameters
     bn_out <- name
     add input_data bn_out
        



genYaml :: Coppe () -> String 
genYaml m = yaml $ build m 

  where
    yaml :: Recipe -> String
    yaml (Seq a b) = yaml a ++ yaml b
    yaml (NamedIntermediate (Identifier i))  = "\t\tname:\n\t\tnom" ++ show i ++ "\n"
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
    pInputs (Just xs) = "\t\tinput_layer:\n" ++ (concatMap (\(Identifier x) -> "\t\t- " ++ "nom" ++ show x ++ "\n") xs) ++ "\n"
    
                                  
    
  
