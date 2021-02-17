module Lib
    ( parseFile
    ) where



import Language.Python.Common
import Language.Python.Version3




parseFile :: FilePath -> IO (Either ParseError (ModuleSpan, [Token]))
parseFile fn = do
  fstr <- readFile fn
  return $ parseModule fstr fn 
