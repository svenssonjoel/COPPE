{-# LANGUAGE ScopedTypeVariables #-}
module Tensor where


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
