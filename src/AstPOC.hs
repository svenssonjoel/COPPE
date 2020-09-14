-- #!/usr/bin/env stack
-- stack --install-ghc runghc

module AstPOC where 

------------------------------------------------------------------------
--Created: mån sep  7 16:12:09 2020 (+0200)
--Last-Updated:
--Filename: AstPOC.hs
--Author: Yinan Yu
--Description:
------------------------------------------------------------------------
import Data.Maybe

class Preset a where
  preset :: a

data Padding = Same | Valid
             deriving (Eq, Show)

instance Preset Padding where
  preset = Valid

data Strides2D = Strides2D Int Int
               deriving (Eq, Show)

data Filters = Filters Int
             deriving (Eq, Show)

data KernelSize2D = KernelSize2D Int Int
                  deriving (Eq, Show)

instance Preset KernelSize2D where
  preset = KernelSize2D 3 3

data NUnits = NUnits Int
            deriving (Eq, Show)

data Initializer = Initializer String
            deriving (Eq, Show)

instance Preset Initializer where
  preset = Initializer "initializer"

data ActivationFunction = ActivationFunction String
            deriving (Eq, Show)

instance Preset ActivationFunction where
  preset = ActivationFunction "activation_function"

data VarianceEpsilon = VarianceEpsilon Float
            deriving (Eq, Show)

instance Preset VarianceEpsilon where
  preset = VarianceEpsilon 0.05

data Decay = Decay Float
            deriving (Eq, Show)

instance Preset Decay where
  preset = Decay 0.1

data TrainingParameters = TrainingParameters {
  weightDecay :: Float,
  learningRate :: Float}
  deriving (Eq, Show)

instance Preset TrainingParameters where
  preset = TrainingParameters {weightDecay = 0.01, learningRate = 0.5}


data Ingredient =
  Relu
  | Add
  | Conv2D Padding Strides2D Filters KernelSize2D TrainingParameters Initializer
  | Dense NUnits Initializer TrainingParameters (Maybe ActivationFunction)
  | BatchNorm VarianceEpsilon Decay
  deriving (Eq, Show)

data Name = Name String | InputLayer | NoName
  deriving (Eq, Show)

type LayerInputs = [Name]

data Layer =
  SimpleLayer Ingredient
  | SimpleLayerWithInputs Ingredient LayerInputs
  | NamedLayer Name Ingredient
  | NamedLayerWithInputs Name Ingredient LayerInputs
                deriving (Eq, Show)


data Recipe = Recipe [Layer]
            deriving (Eq, Show)

resnet32 :: Recipe
resnet32 = Recipe [SimpleLayer (Conv2D Valid (Strides2D 1 1) (Filters 32) preset preset preset),
                   SimpleLayer (BatchNorm preset preset),
                   SimpleLayer Relu,
                   SimpleLayer (Conv2D Valid (Strides2D 1 1) (Filters 32) preset preset preset),
                   NamedLayer (Name "conv") (BatchNorm preset preset),
                   SimpleLayerWithInputs Add [InputLayer, (Name "conv")],
                   SimpleLayer Relu]

data Property = Property [Int]
            deriving (Eq, Show)

type PropertyScope = [(Name, Property)]

lookupProperty :: PropertyScope -> Name -> Property
lookupProperty ps pn = fromJust $ lookup pn (reverse ps)

evalIngredient :: Ingredient -> [Property] -> Property
evalIngredient Relu [input] = input
evalIngredient Add [a, b] = b
evalIngredient (Conv2D Valid (Strides2D sx sy) (Filters f) (KernelSize2D kx ky) _ _) [Property [h,w,c]] = Property [(h `div` kx), (w `div` ky), c]
evalIngredient (Conv2D Same (Strides2D sx sy) (Filters f) (KernelSize2D kx ky) _ _) [input] = input
evalIngredient (Dense _ _ _ _) [input] = input
evalIngredient (BatchNorm _ _) [input] = input


evalLayer :: PropertyScope -> Layer -> (Name, Property)
evalLayer ps (SimpleLayer ingredient) =
  (NoName, evalIngredient ingredient (map snd . take 1 . reverse $ ps))
evalLayer ps (SimpleLayerWithInputs ingredient inputNames) =
  (NoName, evalIngredient ingredient (map (lookupProperty ps) $ inputNames))
evalLayer ps (NamedLayer name ingredient) =
  (name, evalIngredient ingredient (map snd . take 1 . reverse $ ps))
evalLayer ps (NamedLayerWithInputs name ingredient inputNames) =
  (name, evalIngredient ingredient (map (lookupProperty ps) $ inputNames))

evalRecipe :: PropertyScope -> Recipe -> PropertyScope
evalRecipe inputProperties (Recipe layers) =
  inputProperties ++ (evalRecipeLoop layers (snd $ head $ reverse $ inputProperties) [])
  where
    evalRecipeLoop :: [Layer] -> Property -> PropertyScope -> PropertyScope
    evalRecipeLoop [] _ ps = ps
    evalRecipeLoop (l : ls) inputProperty ps = newScope ++ evalRecipeLoop ls inputProperty newScope
      where newScope = ps ++ [(evalLayer ((InputLayer, inputProperty) : ps) l)]


