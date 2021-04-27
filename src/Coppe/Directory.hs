
module Coppe.Directory
  ( coppeDir
  , coppeDirInit
  ) where 

import System.Directory



coppeDir :: IO FilePath
coppeDir =
  do home <- getHomeDirectory
     return (home ++ "/.coppe")


coppeDirInit :: IO ()
coppeDirInit =
  do
    dir <- coppeDir
    putStrLn $ "creating directory: " ++ dir
    createDirectoryIfMissing False dir

