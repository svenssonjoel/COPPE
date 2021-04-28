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

seqTag = Event.mkTag "tag:yaml.org,2002:seq"

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

encodeRecipe :: Recipe -> Maybe (Node ())
encodeRecipe r = case encodeRecipe' r of
                   Nothing -> Nothing
                   Just n  -> Just $ mapping ["params_network" .= n]
  where
    encodeRecipe' Empty = Nothing
    encodeRecipe' Input = Just $ mapping [ "type" .= ("input_layer" :: Text) ]
    encodeRecipe' (Seq rs) = Just $ encodeRecipeList rs
    encodeRecipe' (NamedRecipe n) = Just $ mapping [ "type" .=  (pack n) ]
    encodeRecipe' (Operation i) = encodeIngredient i

    encodeRecipeList :: [Recipe] -> Node ()
    encodeRecipeList rs = Sequence () seqTag (catMaybes (P.map encodeRecipe' rs))

{- Ingredients
   - What to do about the transform field.
     It would be nice to be able to store this information
     as well in the future database.
     Maybe there should be a small language for expressing
     computations such as the dimensionality transform.
-}
encodeIngredient :: Ingredient -> Maybe (Node ())
encodeIngredient i =
  Just $ mapping ([ "type" .= pack (name i) ]  ++
                   encodeHyper (hyper i) )

encodeHyper :: HyperMap -> [Pair] -- (Node (), Node ())
encodeHyper m = Map.foldrWithKey (\k v ps -> (pack k .= encodeParam v):ps) [] m

encodeParam :: Parameter -> Node ()
encodeParam (FunAppParam f a) = undefined
encodeParam (ValParam p) = encodeValue p

encodeValue :: Value -> Node ()
encodeValue (IntVal i)    = mapping ["integer" .= i]
encodeValue (FloatVal f)  = mapping ["float"   .= f]
encodeValue (StringVal s) = mapping ["string"  .= pack (s)]
encodeValue (ListVal ls)  = mapping ["list"    .= Sequence () seqTag (P.map encodeValue ls)]

encodeAnnotation :: Annotation -> Maybe (Node ())
encodeAnnotation = undefined

stripPos :: [Doc (Node a)] -> [Doc (Node ())]
stripPos xs = P.map (fmap f) xs
  where
    f :: (Node a) -> (Node ())
    f (Scalar   _ s) = Scalar () s
    f (Mapping  _ t (mapping)) = Mapping () t (Map.mapKeys f (Map.map f mapping))
    f (Sequence _ t ns) = Sequence () t (P.map f ns)
    f (Anchor   _ id n) = Anchor () id (f n)

