{-# LANGUAGE OverloadedStrings #-}
module Coppe.YParse  where


import Data.Maybe
import Data.YAML
import qualified Data.YAML.Event as Event
import Data.Text
import qualified Data.ByteString as BS
import Data.ByteString.Lazy.UTF8 as BLU
import qualified Data.Map        as Map

import Prelude as P
       
import Coppe.AST


readRecipe :: ByteString -> Recipe
readRecipe yaml = undefined

readRecipeFile :: FilePath -> Recipe
readRecipeFile fp = undefined 

readModule :: ByteString -> Module
readModule yaml =
  case decode1 yaml :: Either (Pos,String) (Node Pos) of
    Left (loc, err) -> error err
    Right tree -> undefined 


      
writeModule :: Module -> [(FilePath, ByteString)] 
writeModule mod =  P.map (\(x,y) -> (x, encodeNode y)) $ encodeModule mod
  where
    encodeModule :: Module -> [(FilePath, [Doc (Node ())])]
    encodeModule = undefined 

encodeRecipe :: Recipe -> (Maybe (Node ()))
encodeRecipe Empty = Nothing
encodeRecipe Input = Just $ mapping [ "type" .= ("input_layer" :: Text) ]
encodeRecipe (Seq r1 r2) =
  let n1 = encodeRecipe r1
      n2 = encodeRecipe r2
  in  case (n1,n2) of
        (Nothing, Nothing) -> Nothing
        (Nothing, Just n)  -> Just n
        (Just n, Nothing)  -> Just n
        {- Not sure how to create valid sequences. -}
        (Just n, Just m)   -> Just $ Sequence () (Event.mkTag "") [n,m]
encodeRecipe (NamedRecipe n) = Just $ mapping [ "type" .=  (pack n) ]
encodeRecipe (Operation i) = encodeIngredient i

{- Ingredients
   - What to do about the transform field.
     It would be nice to be able to store this information
     as well in the future database.
     Maybe there should be a small language for expressing
     computations such as the dimensionality transform. 
-} 
encodeIngredient :: Ingredient -> (Maybe (Node ()))
encodeIngredient i =
  Just $ mapping ([ "type" .= pack (name i) ]  ++
                  encodeHyper (hyper i) )

encodeHyper :: HyperMap -> [Pair] -- (Node (), Node ()) 
encodeHyper m = undefined -- foldWithKey (\(kx,x) -> (pack kx, 
  


encodeAnnotation :: Annotation -> (Maybe (Node ()))
encodeAnnotation = undefined

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

