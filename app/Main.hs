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

-------------------------
-- MNIST Example model -- 
-- Work in progress

mnist_model t =
  let kernel_size = [3,3]
      filters = 32
      strides = [1,1]
  in 
  do
    conv kernel_size strides 32 emptyHyperparameters t
    >>= relu
    >>= conv kernel_size strides 64 emptyHyperparameters
    >>= relu
      




        -- Example 1
        -- model = Sequential()
        -- model.add(Conv2D(32, (3, 3), activation='relu', kernel_initializer='he_uniform', input_shape=(28, 28, 1)))
        -- model.add(MaxPooling2D((2, 2)))
        -- model.add(Flatten())
        -- model.add(Dense(100, activation='relu', kernel_initializer='he_uniform'))
        -- model.add(Dense(10, activation='softmax'))
        -- # compile model
        -- opt = SGD(lr=0.01, momentum=0.9)
        -- model.compile(optimizer=opt, loss='categorical_crossentropy', metrics=['accuracy'])
        -- return model

        -- Example 2 (keras)
        -- model = keras.Sequential(
        --     [
        --         keras.Input(shape=input_shape),
        --         layers.Conv2D(32, kernel_size=(3, 3), activation="relu"),
        --         layers.MaxPooling2D(pool_size=(2, 2)),
        --         layers.Conv2D(64, kernel_size=(3, 3), activation="relu"),
        --         layers.MaxPooling2D(pool_size=(2, 2)),
        --         layers.Flatten(),
        --         layers.Dropout(0.5),
        --         layers.Dense(num_classes, activation="softmax"),
        --     ]
        -- )

    
    
main :: IO ()
main =
  do 
    
    let r = build testNetwork
    --putStrLn $ show r
    case r of
      Left err -> putStrLn $ "Error: " ++ (errorToString err)
      Right r -> do    
        let (Just e) = encodeRecipe r

        putStrLn $ BLU.toString $ encodeNode [(Doc e)]

        let m = readRecipe $ encodeNode [(Doc e)]

        putStrLn $ show m 

    putStrLn "***************************************"

    let input = mkTensor "input_data" [32,32,3] ::Tensor Float 
    let c =  runCoppeArrow testArrow input
    let r' = build c
    case r' of
      Left err -> putStrLn $ "Error: " ++ (errorToString err)
      Right r' -> do    
        let (Just e') =  encodeRecipe r'
      
        putStrLn $ BLU.toString $ encodeNode [(Doc e')]

    putStrLn "***************************************"

    let r = build shouldFail
    case r of
      Left err -> putStrLn $ "Error: " ++ (errorToString err)
      Right r -> do    
        let (Just e) = encodeRecipe r
        putStrLn $ BLU.toString $ encodeNode [(Doc e)]

        let m = readRecipe $ encodeNode [(Doc e)]
        
        putStrLn $ show m 

    putStrLn "***************************************"

    

    
  
    --putStrLn $ show $ numOperations (build testNetwork)
