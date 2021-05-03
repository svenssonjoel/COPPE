{- Files.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

module Coppe.Files
  ( coppeDir
  , coppeDirInit
  ) where 

import System.Directory
import Control.Exception

defaultDir = ".coppe"

coppeDir :: IO FilePath
coppeDir =
  do home <- try getHomeDirectory :: IO (Either IOError FilePath)
     case home of
       Left ex -> do putStrLn "No home directory found, using default coppe directory"
                     return defaultDir
       Right d -> return (d ++ "/.coppe")


coppeDirInit :: IO ()
coppeDirInit =
  do
    dir <- coppeDir
    putStrLn $ "creating directory: " ++ dir
    res <- try (createDirectoryIfMissing False dir) :: IO (Either IOError ())
    case res of
      Left  ex -> putStrLn $ "Exception: " ++ show ex
      Right () -> putStrLn "Success!"

