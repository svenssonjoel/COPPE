module Main where

import Coppe



testNetwork =
  let convParams = [("kernelSize", toValue [34,34 :: Int])
                   ,("strides", toValue [1,1 :: Int])
                   ,("filters", toValue (3 :: Int))]
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
  let r = build testNetwork
  in putStrLn $ show r 
