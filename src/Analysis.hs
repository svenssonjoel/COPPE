
module Analysis ( numOperations
                )
  where

import CoppeAST

{----------------------------------------}
{-             Analysis                 -}


numOperations :: Recipe -> Integer
numOperations r = foldRecipe op 0 r
  where op n Input = n
        op n Empty = n
        op n (Operation _) = n + 1

