{- Arrow.hs

   Copyright: Bo Joel Svensson & Yinan Yu 
-} 


module Coppe.Arrow ( CoppeArrow(..)
                   , coppeArrow
                   , runCoppeArrow
                   )
where

import Coppe.AST
import Coppe.Monad

import Control.Arrow

type CoppeArrow = Kleisli Coppe

runCoppeArrow :: CoppeArrow a b -> a -> Coppe b
runCoppeArrow = runKleisli

coppeArrow :: (a -> Coppe b) -> CoppeArrow a b
coppeArrow f =  Kleisli f
