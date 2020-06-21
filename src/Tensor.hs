module Tensor where


data Type = Float | Double 


data TensorInternal = TensorInternal Integer [Integer] 

data Tensor a = Tensor TensorInternal


mkTensor :: TensorRepr a => Integer -> [Integer] -> Tensor a
mkTensor i d = toTensor (TensorInternal i d)

tensorId :: Tensor a -> Integer
tensorId (Tensor (TensorInternal i _)) = i

tensorDim :: Tensor a -> [Integer]
tensorDim (Tensor (TensorInternal _ d)) = d

class TensorRepr a where
  fromTensor :: Tensor a -> TensorInternal
  toTensor   :: TensorInternal -> Tensor a

instance TensorRepr Float where
  fromTensor (Tensor i) = i
  toTensor   i = Tensor i

instance TensorRepr Double where
  fromTensor (Tensor i) = i
  toTensor   i = Tensor i
