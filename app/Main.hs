{- Main.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

module Main where

import Coppe
import Coppe.Analysis

import Coppe.YParse
import Data.YAML
import Data.ByteString.Lazy.UTF8 as BLU
import Control.Arrow

testNetwork =
  let kernel_size = [34,34] 
      strides     = [1,1]
      filters     = 3
      convParams = emptyHyperparameters
      addParams = emptyHyperparameters
  in
  do
    in_data <- (input :: Coppe (Tensor Float))  -- Float [32,32,3] 
    out_data <- conv kernel_size strides filters convParams in_data
                >>= batchNormalize emptyHyperparameters
                >>= relu
                >>= conv kernel_size strides filters convParams
                >>= batchNormalize emptyHyperparameters
    return out_data 


testArrow =
  let kernel_size = [34,34] 
      strides     = [1,1]
      filters     = 3
      convParams = emptyHyperparameters
      addParams = emptyHyperparameters
  in 
    convA kernel_size strides filters convParams >>>
    batchNormalizeA emptyHyperparameters >>>
    reluA >>>
    convA kernel_size strides filters convParams >>>
    batchNormalizeA emptyHyperparameters >>>
    reluA
    
main :: IO ()
main =
  do 
    
    let r = build testNetwork
    --putStrLn $ show r

    let (Just e) = encodeRecipe r

    putStrLn $ BLU.toString $ encodeNode [(Doc e)]

    let m = readRecipe $ encodeNode [(Doc e)]

    putStrLn $ show m 

    putStrLn "***************************************"

    let c =  do input <- (input :: Coppe (Tensor Float)) -- Float [32,32,3]
                runCoppeArrow testArrow input
    let r' = build c
    let (Just e') =  encodeRecipe r'
      
    putStrLn $ BLU.toString $ encodeNode [(Doc e')]
    
  
    --putStrLn $ show $ numOperations (build testNetwork)
