{- Main.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

module Main where

import Coppe
import Coppe.Analysis

import Coppe.YParse
import Data.YAML
import Data.ByteString.Lazy.UTF8 as BLU

testNetwork =
  let kernel_size = [34,34] 
      strides     = [1,1]
      filters     = 3
      convParams = emptyHyperparameters
      addParams = emptyHyperparameters
  in
  do
    in_data <- inputFloat [32,32,3]
    out_data <- conv kernel_size strides filters convParams in_data
                >>= batchNormalize emptyHyperparameters
                >>= relu
                >>= conv kernel_size strides filters convParams
                >>= batchNormalize emptyHyperparameters
    return out_data 



main :: IO ()
main =
  do 
    
    let r = build testNetwork
    --putStrLn $ show r

    let (Just e) = encodeRecipe r

    putStrLn $ BLU.toString $ encodeNode [(Doc e)]

    let m = readRecipe $ encodeNode [(Doc e)]

    putStrLn $ show m 

    --putStrLn $ show $ numOperations (build testNetwork)
