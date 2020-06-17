
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

data Dimensions = Dimensions [Integer]
  deriving (Eq, Show)

data Identifier = Identifier Integer
  deriving (Eq, Show)

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
