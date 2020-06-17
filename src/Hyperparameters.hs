
module Hyperparameters where

import Data.Maybe

data Strides = Strides [Int]
  deriving (Eq, Show)
data Filters = Filters Int
  deriving (Eq, Show)

data Hyperparameters =
  Hyperparameters { strides :: Maybe Strides
                  , filters :: Maybe Filters }
                  
  deriving (Eq, Show)
