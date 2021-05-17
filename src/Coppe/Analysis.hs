{- Analysis.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

module Coppe.Analysis ( numOperations
                      )
  where

import Coppe.AST

{----------------------------------------}
{-             Analysis                 -}

numOperations :: Recipe -> Integer
numOperations r = foldRecipe op 0 r
  where op n Empty = n
        op n (Operation _) = n + 1

numTrainableLayers :: Recipe -> Integer
numTrainableLayers = undefined

numTrainableWeights :: Recipe -> Integer
numTrainableWeights = undefined

maxMemoryUsage :: Recipe -> Integer
maxMemoryUsage = undefined

