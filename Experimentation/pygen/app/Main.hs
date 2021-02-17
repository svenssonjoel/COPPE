module Main where

import Lib

import Language.Python.Common
import Language.Python.Common.ParseError
import Language.Python.Version3

main :: IO ()
main =
  do
    res <- parseFile "generated.py"
    case res of
      (Right (m,ts)) -> putStrLn $ prettyText m
      (Left (StrError s)) -> putStrLn $ "Error: " ++ s
      (Left (UnexpectedToken t)) -> putStrLn $ "Error unexpected token"
      (Left (UnexpectedChar c l)) -> putStrLn $ "Error unexpected character" ++ show c ++ " " ++ show l
        
  
