module Main where
import Test.QuickCheck as QC

import Lib

main :: IO ()
main = do
  ingredient <- generateArbitraryIngredient
  print ingredient
  recipe <- generateArbitraryRecipe
  print recipe

  QC.quickCheck dimMatch

  print (rankToCandidates 1)
  print (rankToCandidates 2)


  ing <- QC.generate $ nameToIngredient "Dense"
  print (ing)
