module Main where

import Coppe
import Coppe.Analysis



testNetwork =
  let convParams = [("kernelSize", valParam [34,34 :: Int])
                   ,("strides", valParam [1,1 :: Int])
                   ,("filters", valParam (3 :: Int))]
      addParams = emptyHyperparameters
  in
  do
    in_data <- inputFloat [32,32,3]
    out_data <- conv convParams in_data
                >>= batchNormalize emptyHyperparameters
                >>= relu
                >>= conv convParams
                >>= batchNormalize emptyHyperparameters
    return out_data 



main :: IO ()
main =
  do 
    
    let r = build testNetwork
    putStrLn $ show r

    putStrLn $ show $ numOperations (build testNetwork)
