{-# LANGUAGE ScopedTypeVariables #-}
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
                , emptyHyperparameters

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

-- ------------------------------------------------------------ --
-- Tensors

data Type = Float | Double 


data TensorInternal = TensorInternal Integer Type [Integer] 

data Tensor a = Tensor TensorInternal


mkTensor :: forall a. TensorRepr a => Integer -> [Integer] -> Tensor a
mkTensor i d = toTensor (TensorInternal i t d)
  where
    t = (tensorType (undefined :: Tensor a))

tensorId :: Tensor a -> Integer
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

type Identifier = Integer


data Hyperparameters =
  Hyperparameters { strides         :: Maybe Strides
                  , filters         :: Maybe Filters
                  , variance        :: Maybe Float
                  , padding         :: Maybe Padding
                  , initialization  :: Maybe Initialization
                  , kernelSize      :: Maybe Dimensions
                  , inputLayer      :: Maybe [Identifier]}
  deriving (Eq, Show)



emptyHyperparameters = Hyperparameters { strides         = Nothing
                                       , filters         = Nothing
                                       , variance        = Nothing
                                       , padding         = Nothing
                                       , initialization  = Nothing
                                       , kernelSize      = Nothing
                                       , inputLayer      = Nothing }


-- ------------------------------------------------------------ --
-- Layers 


-- May want annotations on Ingredients
data Ingredient = Relu
                | Conv
                | BatchNormalize 
                | Add             
                | Reshape        
                | Dense          -- Dense feed-forward (Fully connected layer)
                | UpSampling     -- May be trained, interpolation, 
                | DownSampling   -- Pooling (function, for example average) Not trained
                | Padd           -- Add Padding
                | Concat         -- Along the channel dimension
  deriving (Eq, Show)

type Name = String
  

data RecipeAnnotation =
  RecipeAnnotation { flopsInference :: Maybe Integer
                   , flopsTraining  :: Maybe Integer  
                   }
  deriving (Eq, Show)


data Recipe =
  Input 
  | Empty
  | NamedIntermediate Identifier -- Maybe remove and attach Identifier to Operation
  | Operation Ingredient Hyperparameters
  | Seq Recipe Recipe
  | Rep Integer Recipe -- What will the identifiers mean in here?
  -- Annotations added by traversals  
  | Annotated RecipeAnnotation Recipe
  deriving (Eq, Show)


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
