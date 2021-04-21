{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE FlexibleInstances #-}

module Coppe.AST (
  -- Layeroperations
  Ingredient(..)
  , hyperSet
  , hyperGet           -- Move to an Ingredient.hs file 
  , ToValue(..)
  , Name
  , Recipe(..)
  , Function(..)
  , Parameter(..)
  
    -- hyperparameters
  , Strides(..)
  , Filters(..)
  , Padding(..)
  , Initialization(..)
  , Dimensions(..)
  , Identifier
  , Hyperparameters(..)
  , emptyHyperparameters
  , HyperMap
  , Annotation
  
    -- Value related stuff
  , filterValToInt
  , strideValToList
  , dimValToList
  
    -- tensors
  , Type(..)
  , Tensor(..)
  , TensorInternal(..)
  , mkTensor
  , tensorId
  , tensorDim
  , tensorReshape
  , TensorRepr(..)
    
    -- Folds and traversals
  ,traverseRecipe
  ,foldRecipe
                
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

tensorReshape :: ([Integer] -> [Integer]) -> Tensor a -> Tensor a
tensorReshape trns (Tensor (TensorInternal i j d)) = Tensor (TensorInternal i j (trns d))


-- Really TensorEltRepr... Maybe change?
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

type Dimensions = [Integer]

type Identifier = String

data Value = IntVal Integer | FloatVal Double
  | StringVal String
  | ListVal [ Value ]
  deriving (Eq, Ord, Show)
  

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

class ToValue a where
  toValue :: a -> Value


instance ToValue Integer where
  toValue = IntVal

instance ToValue Int where
  toValue i = IntVal (toInteger i)
  
instance ToValue Float where
  toValue f = FloatVal (realToFrac f)

instance ToValue Double where
  toValue d = FloatVal d

instance  {-# OVERLAPPABLE #-} ToValue a => ToValue [a] where
  toValue xs = ListVal $ map toValue xs

instance  {-# OVERLAPS #-} ToValue [Char] where
  toValue s = StringVal s

type Param = Value
type Annot = Value

type HyperMap    = Map.Map String Param -- TODO: Parameter. 
type Annotation  = Map.Map String Annot 

type Hyperparameters = [(String, Param)]

-- ------------------------------------------------------------ --
-- Functions 

-- Split into Function and application?

data Function =
  NamedFun String 


type Arguments = [(Maybe String, Parameter)]
  
data Parameter where
  FunAppParam :: Function -> Arguments -> Parameter
  ValParam    :: Param -> Parameter

funApp :: Function -> [(Maybe String, Parameter)] -> Parameter
funApp f args = FunAppParam f args

emptyHyperparameters :: Hyperparameters 
emptyHyperparameters = []

-- ------------------------------------------------------------ --
-- Ingredients 

data Ingredient =
  Ingredient { name :: String
             , annotation :: Annotation
             , hyper :: HyperMap
             , transform :: Dimensions -> Dimensions
             }


hyperSet :: Ingredient -> Hyperparameters -> Ingredient
hyperSet (Ingredient n a h t) ps =
  Ingredient n a (Map.union (Map.fromList ps) h) t

hyperGet :: Ingredient -> HyperMap
hyperGet (Ingredient _ _ h _) = h


              
-- class Show a => Ingredient a  where 
--   name       :: a -> String                 -- Used for printing
--   annotation :: a -> Annotation             -- Get all annotations on the layer 
--   annotate   :: String -> Value -> a -> a   -- Add an annotation key-value pair (or overwrite existing)
--   create     :: Hyperparameters -> a        -- Create an ingredient
--   hyperSet   :: a -> Hyperparameters -> a
--   hyperGet   :: a -> HyperMap
--   transform  :: a -> Dimensions -> Dimensions   -- How does ingredient change tensor dimensionality

-- ------------------------------------------------------------ --
-- Helpers

checkVal :: Value -> Value -> Bool
checkVal (IntVal _) (IntVal _) = True
checkVal (FloatVal _) (FloatVal _) = True
checkVal (ListVal a) (ListVal b) = and (zipWith checkVal a b)
checkVal _ _ = False

extractInts :: String -> Value -> [Integer]
extractInts e (ListVal []) = []
extractInts e (ListVal ((IntVal x):xs)) = x : extractInts e (ListVal xs)
extractInts e _ = error e

dimValToList :: Value -> [Integer]
dimValToList v = extractInts "Dimension specification is not a list of integers" v
 
strideValToList :: Value -> [Integer]
strideValToList v = extractInts "Strides specification is not a list of integers" v

filterValToInt :: Value -> Integer
filterValToInt (IntVal i) = i
filterValToInt _ = error "Filters specification must be an integer"

-- ------------------------------------------------------------ --
-- Layers 

type Name = String
  
data Recipe = Input
            | Empty
            | Operation Ingredient
            | Seq Recipe Recipe
            | Annotated Annotation Recipe

instance Show Recipe where
  show Input = "Input"
  show Empty = "Empty"
  show (Operation i) = name i
  show (Seq r1 r2) = show r1 ++ " ;\n " ++ show r2
  show (Annotated a r) = "<<annot: " ++ show a ++  " " ++ show r ++ ">>"

instance Semigroup Recipe where
  (<>) = Seq
  
instance Monoid Recipe where
  mempty = Empty
  mappend Empty a = a
  mappend a Empty = a
  mappend a b     = Seq a b


-- ------------------------------------------------------------
--  Folds and traversals 

-- Recipe does not fit into Foldable (because it is * and not  * -> *)
-- Recipe also does not fit into Traversable for the same reason.
-- I am not too happy about these.... But lets see how it works out
-- in practice. 

traverseRecipe :: (Recipe -> Recipe) -> Recipe -> Recipe
traverseRecipe f (Seq r1 r2) = Seq (traverseRecipe f r1) (traverseRecipe f r2)
traverseRecipe f r = f r

traverseAnnotate :: (Recipe -> Annotation) -> Recipe -> Recipe
traverseAnnotate f (Seq r1 r2) = Seq (traverseAnnotate f r1) (traverseAnnotate f r2)
traverseAnnotate f r =
  let a = f r
  in Annotated a r


foldRecipe :: ( a -> Recipe -> a) -> a -> Recipe -> a
foldRecipe f a (Seq r1 r2) =
  let a' = foldRecipe f a r1
  in  foldRecipe f a' r2
foldRecipe f a (Annotated _ r) = foldRecipe f a r
foldRecipe f a r = f a r


