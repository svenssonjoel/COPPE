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


data Hyperparameters =
  Hyperparameters { strides         :: Maybe Strides
                  , filters         :: Maybe Filters
                  , variance        :: Maybe Float
                  , padding         :: Maybe Padding
                  , initialization  :: Maybe Initialization
                  , kernelSize      :: Maybe Dimensions
                  , inputLayer      :: Maybe [Identifier]
                  , name            :: Maybe Identifier}
  deriving (Eq, Show)



emptyHyperparameters = Hyperparameters { strides         = Nothing
                                       , filters         = Nothing
                                       , variance        = Nothing
                                       , padding         = Nothing
                                       , initialization  = Nothing
                                       , kernelSize      = Nothing
                                       , inputLayer      = Nothing
                                       , name            = Nothing}


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
  | Operation Ingredient Hyperparameters
  | Seq Recipe Recipe
  | Rep Integer Recipe -- What will the identifiers mean in here?
  -- Annotations added by traversals  
  | Annotated RecipeAnnotation Recipe
  deriving (Eq, Show)


data RecipeT a where
  InputT :: a -> RecipeT a
  EmptyT :: RecipeT ()
  OpT    :: Operation a b -> RecipeT (a -> b)
  AppT   :: RecipeT (a -> b) -> RecipeT a -> RecipeT b 
  SeqT   :: RecipeT (a -> b) -> RecipeT b
  Annot  :: RecipeAnnotation -> RecipeT a -> RecipeT a



  

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
