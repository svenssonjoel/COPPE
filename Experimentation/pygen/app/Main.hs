module Main where

import Lib

import Language.Python.Common
import Language.Python.Common.ParseError
import Language.Python.Version3


test i = 
  do
    (Right (Module stms, _)) <- parseFile "generated.py"
    return $ stms !! i
          

body =
  do
    (Right (Module stms, _)) <- parseFile "generated.py"
    let (Fun a b c d e) = stms !! 6
    return $ d !! 0


main :: IO ()
main =
  do
    res <- parseFile "generated.py"
    case res of
      (Right (m,ts)) ->
        do putStrLn $ prettyText m
           putStrLn "------------------------------------------------------------"
           putStrLn $ show m
           putStrLn "------------------------------------------------------------"
           putStrLn $ show ts
      (Left (StrError s)) -> putStrLn $ "Error: " ++ s
      (Left (UnexpectedToken t)) -> putStrLn $ "Error unexpected token"
      (Left (UnexpectedChar c l)) -> putStrLn $ "Error unexpected character" ++ show c ++ " " ++ show l
        
  
