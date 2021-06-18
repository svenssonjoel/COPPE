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
    in_data <- input (mkTensor "input_data" [32,32,3] :: Tensor Float)
    out_data <- conv kernel_size strides filters convParams in_data
                >>= batchNormalize emptyHyperparameters
                >>= relu
                >>= conv kernel_size strides filters convParams
                >>= batchNormalize emptyHyperparameters
                >>= relu
    return out_data


shouldFail =
  do
    in_a <- input (mkTensor "input_a" [32,32,3] :: Tensor Float)
    in_b <- input (mkTensor "input_b" [15,15] :: Tensor Float)           
    add in_a in_b



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

    let input = mkTensor "input_data" [32,32,3] ::Tensor Float 
    let c =  runCoppeArrow testArrow input
    let r' = build c
    let (Just e') =  encodeRecipe r'
      
    putStrLn $ BLU.toString $ encodeNode [(Doc e')]

    -- putStrLn "***************************************"

    -- let r = build shouldFail
    -- let (Just e) = encodeRecipe r

    -- putStrLn $ BLU.toString $ encodeNode [(Doc e)]

    -- let m = readRecipe $ encodeNode [(Doc e)]

    -- putStrLn $ show m 

    -- putStrLn "***************************************"

    

    
  
    --putStrLn $ show $ numOperations (build testNetwork)
