module CoppeComb ( CoppeArrow(..)
                 , coppeArrow
                 , runCoppeArrow
                 )
where

import CoppeAST
import CoppeMonad

import Control.Arrow

type CoppeArrow = Kleisli Coppe

runCoppeArrow :: CoppeArrow a b -> a -> Coppe b
runCoppeArrow = runKleisli

coppeArrow :: (a -> Coppe b) -> CoppeArrow a b
coppeArrow f =  Kleisli f
