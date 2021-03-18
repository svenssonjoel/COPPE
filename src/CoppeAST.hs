{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}

module CoppeAST (
                -- Layeroperations
                  Ingredient(..)
                , Name
                , Recipe(..)

                -- hyperparameters
                , Strides(..)
                , Filters(..)
                , Padding(..)
                , Initialization(..)
                , Dimensions(..)
                , Identifier
                , Hyperparameters(..)
             --   , emptyHyperparameters

                -- tensors
                , Type(..)
                , Tensor(..)
                , TensorInternal(..)
                , mkTensor
                , tensorId
                , tensorDim
                , TensorRepr(..)
                ) where

import Data.Maybe
import qualified Data.Map as Map

-- ------------------------------------------------------------ --
-- Tensors

data Type = Float | Double 


data TensorInternal = TensorInternal String Type [Integer] 

data Tensor a = Tensor TensorInternal


mkTensor :: forall a. TensorRepr a => String -> [Integer] -> Tensor a
mkTensor nom d = toTensor (TensorInternal nom t d)
  where
    t = (tensorType (undefined :: Tensor a))

tensorId :: Tensor a -> String
tensorId (Tensor (TensorInternal i _ _)) = i

tensorDim :: Tensor a -> [Integer]
tensorDim (Tensor (TensorInternal _ _ d)) = d

class TensorRepr a where
  fromTensor :: Tensor a -> TensorInternal
  toTensor   :: TensorInternal -> Tensor a
  tensorType :: Tensor a -> Type

instance TensorRepr Float where
  fromTensor (Tensor i) = i
  toTensor   i = Tensor i
  tensorType _ = Float

instance TensorRepr Double where
  fromTensor (Tensor i) = i
  toTensor   i = Tensor i
  tensorType _ = Double


-- ------------------------------------------------------------ --
-- Hyperparameters 

data Strides = Strides [Integer]
  deriving (Eq, Show)

data Filters = Filters Integer
  deriving (Eq, Show)

data Padding = Same | Valid 
  deriving (Eq, Show)

data Initialization = Random
  deriving (Eq, Show)

data Dimensions = Dimensions [Integer]
  deriving (Eq, Show)

type Identifier = String


-- data Hyperparameters =
--   Hyperparameters { strides         :: Maybe Strides
--                   , filters         :: Maybe Filters
--                   , variance        :: Maybe Float
--                   , padding         :: Maybe Padding
--                   , initialization  :: Maybe Initialization
--                   , kernelSize      :: Maybe Dimensions
--                   , inputLayer      :: Maybe [Identifier]
--                   , name            :: Maybe Identifier}
--   deriving (Eq, Show)



-- emptyHyperparameters = Hyperparameters { strides         = Nothing
--                                        , filters         = Nothing
--                                        , variance        = Nothing
--                                        , padding         = Nothing
--                                        , initialization  = Nothing
--                                        , kernelSize      = Nothing
--                                        , inputLayer      = Nothing
--                                        , name            = Nothing}


data Value = IntVal Integer | FloatVal Double
  | ListVal [ Value ]

instance Num Value where
  (+) (IntVal i) (IntVal j) = IntVal (i+j)
  (+) (FloatVal i) (FloatVal j) = FloatVal (i+j)
  (+) _ _ = error "Value: Mismatching types"
  (-) (IntVal i) (IntVal j) = IntVal (i-j)
  (-) (FloatVal i) (FloatVal j) = FloatVal (i-j)
  (-) _ _ = error "Value: Mismatching types"
  (*) (IntVal i) (IntVal j) = IntVal (i*j)
  (*) (FloatVal i) (FloatVal j) = FloatVal (i*j)
  (*) _ _ = error "Value: Mismatching types"
  abs (IntVal i) = IntVal (abs i)
  abs (FloatVal i) = FloatVal (abs i)
  abs _ = error "Value: abs not supported on ListVal"
  signum (IntVal i) = IntVal (signum i)
  signum (FloatVal i) = FloatVal (signum i)
  signum _ = error "Value: signum not supported on ListVal"
  fromInteger i = IntVal (fromInteger i)
  

type Param = Value
type Annot = Value

type HyperMap    = Map.Map String Param
type Annotation  = Map.Map String Annot

type Hyperparameters = [(String, Param)]
                 
class Ingredient a  where 
  name       :: a -> String
  annotation :: a -> Annotation 
  annotate   :: String -> Value -> a -> a
  create     :: Hyperparameters -> a

-- ------------------------------------------------------------ --
-- Some example ingredients

data Conv = Conv HyperMap Annotation 

instance Ingredient Conv where
  name _ = "conv"
  annotation (Conv h a) = a
  annotate s v (Conv h a) = Conv h (Map.insert s v a)
  create hyps = Conv (Map.fromList hyps) (Map.empty)

instance Show Conv where
  show = name 

mkConv :: Hyperparameters -> Conv
mkConv = create

data Relu = Relu HyperMap Annotation

instance Ingredient Relu where
  name _ = "relu"
  annotation (Relu h a) = a
  annotate s v (Relu h a) = Relu h (Map.insert s v a)
  create hyps = Relu (Map.fromList hyps) (Map.empty)

instance Show Relu where
  show = name

mkRelu :: Hyperparameters -> Relu
mkRelu = create

-- ------------------------------------------------------------ --
-- Layers 

type Name = String
  
data Recipe where
  Input :: Recipe
  Empty :: Recipe
  Operation :: (Ingredient a) => a -> Recipe
  Seq :: Recipe -> Recipe -> Recipe
  Annotated :: Annotation -> Recipe


-- data Recipe =
--   Input 
--   | Empty
--   | Operation Ingredient Hyperparameters
--   | Seq Recipe Recipe
--   | Rep Integer Recipe -- What will the identifiers mean in here?
--   -- Annotations added by traversals  
--   | Annotated RecipeAnnotation Recipe
--   deriving (Eq, Show)

-- Seq (Seq x y) z)

-- Can annotate one layer or a sequence of many layers. 
-- Seq (Annotated r (Seq x y)  (Seq z (Annotated r1 k) ) 

instance Semigroup Recipe where
  (<>) = Seq
  
instance Monoid Recipe where
  mempty = Empty
  mappend Empty a = a
  mappend a Empty = a
  mappend a b     = Seq a b


-- Recipe does not fit into Foldable (because it is * and not  * -> *)
-- Recipe also does not fit into Traversable for the same reason.

--foldIngredients :: (Ingredient -> 
