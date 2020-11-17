-- TODO:
-- implement arbitrary for all ingredients
-- implement arbitrary for all layers
-- implement arbitrary for all recipes
-- write property checks

module Lib where

import Data.Maybe
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Data.Tuple.Extra as Tuple
import qualified Test.QuickCheck as QC
import Test.QuickCheck.Arbitrary as A (Arbitrary, arbitrary)
import Control.Monad

type Name = String
type NumInputs = Int
type Rank = Int

class Preset a where
  preset :: a

-- Section 1: define ingredients
-- An ingredient is a "layer" in the deep learing context
-- An ingredient is specified by a type (e.g. conv2d, dense, relu, ...) and its hyperparameters
-- For each hyparameter, define the following:
-- 1) data hyperparam
-- 2) Preset (default value)
-- 3) Arbitrary

-- Conv2D hyperparams
data Padding = Same | Valid
             deriving (Eq, Show)

-- Conv2D.Padding
instance Preset Padding where
  preset = Valid

instance Arbitrary Padding where
  arbitrary = QC.oneof [pure Same, pure Valid]

-- Conv2D.Strides2D
data Strides2D = Strides2D Int Int
               deriving (Eq, Show)

instance Arbitrary Strides2D where
  arbitrary = do
    x <- QC.choose (0, 255)
    y <- QC.choose (0, 255)
    pure (Strides2D x y)

-- Conv2D.Filters
data Filters = Filters Int
             deriving (Eq, Show)

instance Arbitrary Filters where
  arbitrary = do
    x <- QC.choose (0::Int, 10::Int)
    pure (Filters (2 ^ x))

-- Conv2D.KernelSize2D
data KernelSize2D = KernelSize2D Int Int
                  deriving (Eq, Show)

instance Preset KernelSize2D where
  preset = KernelSize2D 3 3

instance Arbitrary KernelSize2D where
  arbitrary = do
    h <- QC.choose (0, 5)
    pure (KernelSize2D (h*2+1) (h*2+1))

-- Dense hyperparams
-- Dense.NUnits: integer + [TODO] other constraints
data NUnits = NUnits Int
            deriving (Eq, Show)

instance Preset NUnits where
  preset = NUnits 10

instance Arbitrary NUnits where
  arbitrary = do
    n <- QC.choose (5, 8192)
    pure (NUnits n)

-- Dense.Initializer: choose from a predefined set
data Initializer = Initializer String
            deriving (Eq, Show)

instance Preset Initializer where
  preset = Initializer "xavier_uniform"

instance Arbitrary Initializer where
  arbitrary = do
    initializer <- QC.elements["xavier_uniform",
                               "he_uniform"]
    pure (Initializer initializer)


-- Dense.ActivationFunction: choose from a predefined set
data ActivationFunction = ActivationFunction String
            deriving (Eq, Show)

instance Preset ActivationFunction where
  preset = ActivationFunction "null"

instance Arbitrary ActivationFunction where
  arbitrary = do
    activationFunction <- QC.elements["null"]
    pure (ActivationFunction activationFunction)

-- Batchnormalize hyperparams
-- Batchnormalize.VarianceEpsilon
data VarianceEpsilon = VarianceEpsilon Float
            deriving (Eq, Show)

instance Preset VarianceEpsilon where
  preset = VarianceEpsilon 0.001

instance Arbitrary VarianceEpsilon where
  arbitrary = do
    varianceEpsilon <- QC.choose(0, 0.2)
    pure (VarianceEpsilon varianceEpsilon)

-- Batchnormalize.Decay
data Decay = Decay Float
            deriving (Eq, Show)

instance Preset Decay where
  preset = Decay 0.9

instance Arbitrary Decay where
  arbitrary = do
    decay <- QC.choose(0.6, 1)
    pure (Decay decay)

-- Training parameters
-- [TODO] dense.Initializer is also part of training parameters.
-- [TODO] wrap training parameters into a (runtime) variable class
data TrainingParameters = TrainingParameters {
  weightDecay :: Float,
  learningRate :: Float}
  deriving (Eq, Show)

instance Preset TrainingParameters where
  preset = TrainingParameters {weightDecay = 0.01, learningRate = 0.5}

instance Arbitrary TrainingParameters where
  arbitrary = do
    _weightDecay <- QC.choose(0, 0.2)
    _learningRate <- QC.choose(0, 0.2)
    pure (TrainingParameters _weightDecay _learningRate)

-- Ingredient.definition
data Ingredient =
  Relu
  | Add
  | Conv2D Padding Strides2D Filters KernelSize2D TrainingParameters Initializer
  | Dense NUnits Initializer TrainingParameters (Maybe ActivationFunction)
  | BatchNorm VarianceEpsilon Decay
--  | RecipeIngredient Recipe -- [TODO] Implement the unification of recipe and ingredient so we can have recursive recipes
  -- [TODO] Also inlcude pre-defined recipes!
  -- [TODO] Decide what is the common interface: ingredient or recipe
  deriving (Eq, Show)


-- Each ingredient has a set of attriubtes
ingredientAttr :: Map.Map String (NumInputs, Rank)
ingredientAttr = Map.fromList [("Dense", (1, 1)),
                               ("Conv2D", (1, 3)),
                               ("Relu", (1, 10)),
                               ("BatchNorm", (1, 3)),
                               ("Add", (2, 10))]

type Candidates = [String]
rankToCandidates :: Rank -> Candidates
rankToCandidates rank = Map.keys (Map.filter (\p -> (snd p) <= rank || ((snd p) == 10)) ingredientAttr)
-- rankToCandidates rank = do
--   case rank of
--     0 -> Map.keys ingredientAttr
--     otherwise -> Map.keys (Map.filter (\p -> (snd p) <= rank || ((snd p) == 0)) ingredientAttr)


-- [TODO] restrict the set of possible ingredients for a given ingredient
ingredientName :: Ingredient -> String


ingredientName (Dense _ _ _ _) = "Dense"
ingredientName (Conv2D _ _ _ _ _ _) = "Conv2D"
ingredientName (BatchNorm _ _) = "BatchNorm"
ingredientName (Add) = "Add"
ingredientName (Relu) = "Relu"


ingredientToRank :: Ingredient -> Rank
ingredientToRank ingredient =
  snd $ ingredientAttr Map.! name
  where
    name = ingredientName ingredient


instance Arbitrary Ingredient where
  -- [FIXME] Use the same TrainingParameter for all layers. Refine the abstraction
  arbitrary = QC.oneof[
    pure Relu,
    pure Add,
    do
      padding <- arbitrary
      strides2D <- arbitrary
      filters  <- arbitrary
      kernelSize2D <- arbitrary
      trainingParameters <- arbitrary
      initializer <- arbitrary
      pure $ Conv2D padding strides2D filters kernelSize2D trainingParameters initializer,
    do
      nUnits <- arbitrary
      initializer <- arbitrary
      trainingParameters <- arbitrary
      activationFunction <- arbitrary
      pure $ Dense nUnits initializer trainingParameters activationFunction,
    do
      varianceEpsilon <- arbitrary
      decay <- arbitrary
      pure $ BatchNorm varianceEpsilon decay
    ]


nameToIngredient :: String -> QC.Gen Ingredient
nameToIngredient name = do
  case name of
    "Dense" -> do
      nUnits <- arbitrary
      initializer <- arbitrary
      trainingParameters <- arbitrary
      activationFunction <- arbitrary
      pure $ Dense nUnits initializer trainingParameters activationFunction
    "Conv2D" -> do
      padding <- arbitrary
      strides2D <- arbitrary
      filters  <- arbitrary
      kernelSize2D <- arbitrary
      trainingParameters <- arbitrary
      initializer <- arbitrary
      pure $ Conv2D padding strides2D filters kernelSize2D trainingParameters initializer
    "Add" -> do
      pure Add
    "Relu" -> do
      pure Relu
    "BatchNorm" -> do
      varianceEpsilon <- arbitrary
      decay <- arbitrary
      pure $ BatchNorm varianceEpsilon decay


candidatesToIngredient :: Candidates -> QC.Gen Ingredient
candidatesToIngredient candidates =
  QC.oneof $ map nameToIngredient candidates


generateArbitraryIngredient :: IO Ingredient
generateArbitraryIngredient = QC.generate arbitrary

-- Section 2: define layers
-- A layer is an ingredient wrapped in some meta data
-- Meta data includes: 1) a name, 2) its inputs

type LayerInputs = [String]

data Layer =
  SimpleLayer Ingredient
  | SimpleLayerWithInputs Ingredient LayerInputs
  | NamedLayer Name Ingredient
  | NamedLayerWithInputs Name Ingredient LayerInputs
                deriving (Eq, Show)

-- Helper functions for layer
layerToIngredient :: Layer -> Ingredient
layerToIngredient layer = do
  case layer of
    SimpleLayer ingredient -> ingredient
    SimpleLayerWithInputs ingredient _ -> ingredient
    NamedLayer _ ingredient  -> ingredient
    NamedLayerWithInputs _ ingredient _ -> ingredient

-- Section 3: define recipes
-- A recipe is a collection of layers

-- Definition
data Recipe = Recipe [Layer]
            deriving (Eq, Show)

type SubRecipe = Recipe
type LayerStates = (Rank, Candidates, SubRecipe)


-- Generate arbitrary a recipe
arbitraryRecursive :: ([Layer], [LayerStates]) -> Int -> QC.Gen ([Layer], [LayerStates])
arbitraryRecursive ([], inputStates) _ = do
  ingredient <- candidatesToIngredient $ rankToCandidates rank
  let newRank = min rank (ingredientToRank ingredient)
  let newLayer = SimpleLayer ingredient
  pure ([newLayer], [(newRank, rankToCandidates newRank, Recipe [newLayer])])
  where
    rank = Tuple.fst3 $ last inputStates


arbitraryRecursive (layers, layerStates) _ = do
  -- [FIXME]: Generate connection first.
  -- [FIXME]: For now connections are linear
  ingredient <- candidatesToIngredient $ rankToCandidates rank
  let newRank = min rank (ingredientToRank ingredient)
  let newLayer = SimpleLayer ingredient
  pure $ (layers ++ [SimpleLayer ingredient], layerStates ++ [(newRank, rankToCandidates newRank, Recipe [newLayer])])
  where
    rank = Tuple.fst3 $ last layerStates

instance Arbitrary Recipe where
  arbitrary = do
    nLayers <- QC.choose (1, 20)
    (layers, _) <- (foldM arbitraryRecursive ([], [(3, rankToCandidates 3, Recipe [SimpleLayer (Conv2D Valid (Strides2D 1 1) (Filters 32) preset preset preset)])]) [0..nLayers]) -- [FIXME] Fix input layer declaration
    pure (Recipe layers)


resnet32 :: Recipe
resnet32 = Recipe [SimpleLayer (Conv2D Valid (Strides2D 1 1) (Filters 32) preset preset preset),
                   SimpleLayer (BatchNorm preset preset),
                   SimpleLayer Relu,
                   SimpleLayer (Conv2D Valid (Strides2D 1 1) (Filters 32) preset preset preset),
                   NamedLayer "conv" (BatchNorm preset preset),
                   SimpleLayerWithInputs Add ["input_layer", "conv"],
                   SimpleLayer Relu]

generateArbitraryRecipe :: IO Recipe
generateArbitraryRecipe = QC.generate arbitrary

-- Section 4: define properties
type PropertyName = String

data Property = Property [Int]
            deriving (Eq, Show)

type PropertyScope = [(PropertyName, Property)]

lookupProperty :: PropertyScope -> PropertyName -> Property
lookupProperty ps pn = fromJust $ lookup pn (reverse ps)

evalIngredient :: Ingredient -> [Property] -> Property
evalIngredient Relu [input] = input
evalIngredient Add [a, b] = b
evalIngredient (Conv2D Valid (Strides2D sx sy) (Filters f) (KernelSize2D kx ky) _ _) [Property [h,w,c]] = Property [(h `div` kx), (w `div` ky), c]
evalIngredient (Conv2D Same (Strides2D sx sy) (Filters f) (KernelSize2D kx ky) _ _) [input] = input
evalIngredient (Dense _ _ _ _) [input] = input
evalIngredient (BatchNorm _ _) [input] = input

evalLayer :: PropertyScope -> Layer -> (PropertyName, Property)
evalLayer ps (SimpleLayer ingredient) =
  ("", evalIngredient ingredient (map snd . take 1 . reverse $ ps))
evalLayer ps (SimpleLayerWithInputs ingredient inputNames) =
  ("", evalIngredient ingredient (map (lookupProperty ps) $ inputNames))
evalLayer ps (NamedLayer name ingredient) =
  (name, evalIngredient ingredient (map snd . take 1 . reverse $ ps))
evalLayer ps (NamedLayerWithInputs name ingredient inputNames) =
  (name, evalIngredient ingredient (map (lookupProperty ps) $ inputNames))

evalRecipe :: PropertyScope -> Recipe -> PropertyScope
evalRecipe inputProperties (Recipe layers) =
  inputProperties ++ (evalRecipeLoop layers (snd $ head $ reverse $ inputProperties) [])
  where
    evalRecipeLoop :: [Layer] -> Property -> PropertyScope -> PropertyScope
    evalRecipeLoop [] inputProperty ps = ps
    evalRecipeLoop (l : ls) inputProperty ps = newScope ++ evalRecipeLoop ls inputProperty newScope
      where newScope = ps ++ [(evalLayer (("input_layer", inputProperty) : ps) l)]



-- Section 5: property checks
-- I. Property checks for networks:
-- There are three levels of checks:
-- level 0 [network compilation]: valid network (hyperparams in bound; dimensions match; other requirements such as number of training parameters, layer depths, etc; some properties as a function of the network substructure)
-- level 1 [training declaration]: valid training variables (training variables in bound, training procedure properties such as learning rate should decrease over time, etc)
-- level 2 [runtime properties]: generate arbitrary data to test the network. Here we are testing properties as a function of input data (both for training and testing)
-- II. Property checks for data:
-- Generate arbitrary networks to test data properties
dimMatch :: Recipe -> Bool
dimMatch recipe = True -- [TODO] not implemented yet
