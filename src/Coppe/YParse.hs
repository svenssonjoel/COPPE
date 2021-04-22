{-# LANGUAGE OverloadedStrings #-}
module Coppe.YParse  where


import Data.YAML
import Data.Text
import qualified Data.ByteString as BS
import Data.ByteString.Lazy.UTF8 as BLU
import qualified Data.Map        as Map

import Prelude as P
       
import Coppe.AST




readModule :: ByteString -> Module
readModule yaml =
  case decode1 yaml :: Either (Pos,String) (Node Pos) of
    Left (loc, err) -> error err
    Right tree -> undefined 


      
writeModule :: Module -> ByteString
writeModule mod = encodeNode encodeModule mod
  where
    encodeModule :: Module -> [Doc (Node ())]
    encodeModule = undefined 
  

-- data Label = Label Text
-- data Person = Person Text Int
--   deriving Show

-- instance ToYAML Person where
--     -- this generates a Node
--     toYAML (Person n a) = mapping [ "name" .= n, "age" .= a]

-- instance FromYAML Person where
--    parseYAML = withMap "Person" $ \m -> Person
--        <$> m .: "name"
--        <*> m .: "age"

-- instance ToYAML Label where
--     -- this generates a Node
--     toYAML (Label n) = mapping [ "Label" .= n]

-- instance FromYAML Label where
--    parseYAML = withMap "Label" $ \m -> Label
--        <$> m .: "Label"

-- test = BLU.fromString "paramsNetwork:\n - apa: 13\n - Bepa 14\n\nTestNetwork:\n - kurt: 14\n"

stripPos :: [Doc (Node a)] -> [Doc (Node ())]
stripPos xs = P.map (fmap f) xs
  where
    f :: (Node a) -> (Node ())
    f (Scalar   _ s) = Scalar () s
    f (Mapping  _ t (mapping)) = Mapping () t (Map.mapKeys f (Map.map f mapping))
    f (Sequence _ t ns) = Sequence () t (P.map f ns)
    f (Anchor   _ id n) = Anchor () id (f n)

