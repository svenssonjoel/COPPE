
module Hyperparameters where

import Data.Maybe

data Strides = Strides [Int]
  deriving (Eq, Show)

data Filters = Filters Int
  deriving (Eq, Show)

data Padding = Same
  deriving (Eq, Show)

data Initialization = Random
  deriving (Eq, Show)

data Dimensions = Dimensions [Int]
  deriving (Eq, Show)

data Hyperparameters =
  Hyperparameters { strides    :: Maybe Strides
                  , filters    :: Maybe Filters
                  , variance   :: Maybe Float
                  , padding    :: Maybe Padding
                  , init       :: Maybe Initialization
                  , kernelSize :: Maybe Dimensions }
  
  deriving (Eq, Show)
