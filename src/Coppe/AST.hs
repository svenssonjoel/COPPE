{- AST.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 


{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE FlexibleInstances #-}

module Coppe.AST (
  -- Module
  Module(..)
  -- Layeroperations
  , Ingredient(..)
  , hyperSet
  , hyperGet           -- Move to an Ingredient.hs file
  , Value(..)
  , ToValue(..)
  , valParam 
  , Name
  , Recipe(..)
  , Function(..)
  , Parameter(..)
  , Arguments(..)
  
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
--  , tensorReshape
  , TensorRepr(..)
    
    -- Folds and traversals
  ,traverseRecipe
  ,foldRecipe
                
  ) where

import Data.Maybe
import qualified Data.Map as Map
import Coppe.Tinylang.AbsTinylang

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

-- tensorReshape :: ([Integer] -> [Integer]) -> Tensor a -> Tensor a
-- tensorReshape trns (Tensor (TensorInternal i j d)) = Tensor (TensorInternal i j (trns d))


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

data Value =
  IntVal Integer
  | FloatVal Double
  | BoolVal  Bool
  | StringVal String
  | ListVal [ Value ]
  | CloVal Exp [Arg] HyperMap Annotation (Map.Map String Value)
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
  fromValue :: Value -> a 

instance ToValue Integer where
  toValue = IntVal
  fromValue (IntVal i) = fromInteger i
  fromValue x = error $ "fromValue integer: " ++ show x

instance ToValue Int where
  toValue i = IntVal (toInteger i)
  fromValue (IntVal i) = fromInteger i
  fromValue x = error $ "fromValue int: " ++ show x
  
instance ToValue Float where
  toValue f = FloatVal (realToFrac f)
  fromValue (FloatVal f) = (realToFrac f)
  fromValue x = error $ "fromValue float: " ++ show x

instance ToValue Bool where
  toValue b = BoolVal b
  fromValue (BoolVal b) = b
  fromValue x = error $ "fromValue bool: " ++ show x

instance ToValue Double where
  toValue d = FloatVal d
  fromValue (FloatVal d) = d
  fromValue x = error $ "fromValue double: " ++ show x

instance  {-# OVERLAPPABLE #-} ToValue a => ToValue [a] where
  toValue xs = ListVal $ map toValue xs
  fromValue (ListVal xs) = map fromValue xs
  fromValue x = error $ "fromValue list: " ++ show x

instance  {-# OVERLAPS #-} ToValue [Char] where
  toValue s = StringVal s
  fromValue (StringVal s) = s
  fromValue x = error $ "fromValue string: " ++ show x

type Param = Value
type Annot = Value

type HyperMap    = Map.Map String Parameter -- TODO: Parameter. 
type Annotation  = Map.Map String Annot 

type Hyperparameters = [(String, Parameter)]

-- ------------------------------------------------------------ --
-- Functions 

-- Split into Function and application?

data Function =
  NamedFun String
  deriving (Eq, Ord, Show)

type Arguments = [(Maybe String, Parameter)]
  
  
data Parameter = 
  FunAppParam Function Arguments 
  | ValParam Param 
  deriving (Eq, Ord, Show)

valParam :: ToValue a => a -> Parameter
valParam v = ValParam (toValue v)

funApp :: Function -> [(Maybe String, Parameter)] -> Parameter
funApp f args = FunAppParam f args

emptyHyperparameters :: Hyperparameters 
emptyHyperparameters = []

-- ------------------------------------------------------------ --
-- Expressions

{-
   fun ks ss fs dim -> 
      let ndims  = length dim in 
      let ok     = length ks = ndims - 1 && length ss = ndims - 1 in 
      let dims   = take (ndims - 1) dim in 
      let newdim = zipWith3 (fun d k s -> (div (d - k + 2 * (k - 1)) (s + 1)))
                   dims ks ss
-} 

         


-- ------------------------------------------------------------ --
-- Ingredients 

data Ingredient =
  Ingredient { name       :: String
             , annotation :: Annotation
             , hyper      :: HyperMap
             , trainable  :: Bool
         --    , numWeights :: Exp -- :: Dimensions -> Int    
             , transform  :: Exp -- :: Dimensions -> Dimensions   
             }

hyperSet :: Ingredient -> Hyperparameters -> Ingredient
hyperSet (Ingredient n a h trnble t) ps =
  Ingredient n a (Map.union (Map.fromList ps) h) trnble t

hyperGet :: Ingredient -> HyperMap
hyperGet (Ingredient _ _ h _ _) = h

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

-- params_network is a tag present in recipes. 

data Module = Module  [(Name, Recipe)] 
  
data Recipe =  Empty
            | NamedRecipe Name
            | Operation Ingredient
            | Seq [Recipe]    -- Will get more obvious if this is a list of recipies. 
            | Annotated Annotation Recipe
--   deriving (Eq, Ord, Show)   -- We may want this

instance Show Recipe where
  show Empty = "Empty"
  show (NamedRecipe n) = n
  show (Operation i) = name i
  show (Seq []) = ""
  show (Seq (r:rs)) = show r ++ ";\n" ++ show (Seq rs)
  show (Annotated a r) = "<<annot: " ++ show a ++  " " ++ show r ++ ">>"

-- This way we loose nesting.
instance Semigroup Recipe where
  (<>) Empty    Empty    = Empty
  (<>) r1       Empty    = r1
  (<>) Empty    r2       = r2
  (<>) (Seq r1) (Seq r2) = Seq (r1 ++ r2)
  (<>) (Seq r1) r2       = Seq (r1 ++ [r2])
  (<>) r1       (Seq r2) = Seq (r1:r2)
  (<>) r1       r2       = Seq [r1,r2]
                            
-- (<>) is infixr     
  
instance Monoid Recipe where
  mempty = Empty
  mappend = (<>)


-- ------------------------------------------------------------
--  Folds and traversals 

-- Recipe does not fit into Foldable (because it is * and not  * -> *)
-- Recipe also does not fit into Traversable for the same reason.
-- I am not too happy about these.... But lets see how it works out
-- in practice. 

traverseRecipe :: (Recipe -> Recipe) -> Recipe -> Recipe
traverseRecipe f (Seq rs) = Seq (map (traverseRecipe f) rs)
traverseRecipe f r = f r

traverseAnnotate :: (Recipe -> Annotation) -> Recipe -> Recipe
traverseAnnotate f (Seq rs) = Seq (map (traverseAnnotate f) rs) -- Seq (traverseAnnotate f r1) (traverseAnnotate f r2)
traverseAnnotate f r =
  let a = f r
  in Annotated a r

foldRecipe :: ( a -> Recipe -> a) -> a -> Recipe -> a
foldRecipe f a (Seq [])     = a
foldRecipe f a (Seq (r:rs)) = f (foldRecipe f a (Seq rs)) r 
foldRecipe f a (Annotated _ r) = foldRecipe f a r
foldRecipe f a r = f a r


