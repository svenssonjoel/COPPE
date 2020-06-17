
-- Experimentation
module Coppe
  (rep
  ,testweb)
  where 

import Control.Monad.Writer

import Hyperparameters

data LayerOperation = Relu | Conv | BatchNormalize | Add
  deriving (Eq, Show)

type Name = String

data Recipe =
  Input
  | Empty
  | NamedIntermediate Name
  | Operation LayerOperation Hyperparameters
  | Seq Recipe Recipe
  deriving (Eq, Show)



rep :: Int -> Recipe -> Recipe
rep 0 r = Empty
rep n r = r `Seq` (rep (n-1) r)


testweb :: Recipe
testweb = Empty
  
