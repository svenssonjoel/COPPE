{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

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

readRecipe :: ByteString -> Maybe Recipe
readRecipe yaml =
  case decode1 yaml :: Either (Pos,String) (Node Pos) of
    Left (loc, err) -> error err
    Right tree -> decodeRecipe tree

decodeRecipe :: Node Pos -> Maybe Recipe
decodeRecipe (Mapping _ _ m) =
  case parseEither ((m .: "params_network") :: Parser (Node Pos)) of
    Left (pos,str) -> Nothing
    Right n -> decodeLayers n                 
decodeRecipe _ = Nothing

decodeLayers :: Node Pos -> Maybe Recipe
decodeLayers (Sequence _ _ ls) =
  if (P.length layers' < P.length layers) then Nothing
  else  Just $ Seq (catMaybes layers) 
  where
    layers = P.map decodeLayer ls
    layers' = catMaybes layers
  
decodeLayer :: Node Pos -> Maybe Recipe
decodeLayer (Mapping _ _ m) = decodeLayerMapping m
decodeLayer (Sequence _ _ s) = decodeLayerSequence s
  
decodeLayerMapping :: Map.Map (Node Pos) (Node Pos) -> Maybe Recipe
decodeLayerMapping m = 
  case parseEither ((m .: "type") :: Parser Text) of
    Left (pos,str) -> Nothing
    Right n -> case n of
                 "input_layer" -> Just Input
                 "annotated"   -> decodeAnnotated m 
                 _ -> error "This is not an input layer" 

decodeAnnotated :: Map.Map (Node Pos) (Node Pos) -> Maybe Recipe
decodeAnnotated m = do
  annotation_node <- case parseEither ((m .: "annotation") :: Parser (Node Pos)) of
                       Left _ -> Nothing
                       Right n -> Just n
  recipe_node <- case parseEither ((m .: "recipe") :: Parser (Node Pos)) of
                   Left _ -> Nothing
                   Right n -> Just n

  annotation <- decodeAnnotationNode annotation_node
  recipe <- decodeRecipe recipe_node
  return $ Annotated annotation recipe 
  

decodeAnnotationNode :: Node Pos -> Maybe Annotation
decodeAnnotationNode (Mapping _ _ m) = undefined 
decodeAnnotationNode _ = Nothing -- malformed annotation
  
decodeValue :: Node Pos -> Maybe Value
decodeValue (Mapping _ _ m) =   -- This mapping should be just one key/value pair
  case elts of
    [(Just "integer",n)] -> undefined
    [(Just "float", f)]  -> undefined
    [(Just "string", s)] -> undefined
    [(Just "list", l)]   -> undefined
    _ -> Nothing -- Malformed value 

  where elts = Map.toList (Map.mapKeys decodeKey m)

        decodeKey :: Node Pos -> Maybe Text
        decodeKey n =
          case parseEither ((parseYAML n) :: Parser Text) of
            Left _ -> Nothing
            Right s -> Just s
          
        

  
decodeLayerSequence :: [Node Pos] -> Maybe Recipe
decodeLayerSequence s = error "Inside the layer Sequence"

readRecipeFile :: FilePath -> Recipe
readRecipeFile fp = undefined

--readModule :: ByteString -> Module
--readModule yaml =
--  case decode1 yaml :: Either (Pos,String) (Node Pos) of
--    Left (loc, err) -> error err
--    Right tree -> undefined

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
    encodeRecipe' (NamedRecipe n) = Just $ mapping [ "type" .= (pack n) ]
    encodeRecipe' (Operation i) = encodeIngredient i
    encodeRecipe' (Annotated a r) =
      let r' = encodeRecipe r
      in case r' of
         Just recipe -> Just $ mapping [ "type" .= (pack "annotated"),
                                         "annotation" .= encodeAnnotation a,
                                         "recipe" .= recipe]
         Nothing -> Nothing               

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
                  (if not (P.null pairs) then [ "annotation" .= m ] else []) ++ 
                   encodeHyper (hyper i) )
  where m = mapping pairs
        pairs = (encodeAnnotation (annotation i))

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

encodeAnnotation :: Annotation -> [Pair]
encodeAnnotation m = Map.foldrWithKey (\k v as -> (pack k .= encodeValue v):as) [] m

stripPos :: [Doc (Node a)] -> [Doc (Node ())]
stripPos xs = P.map (fmap f) xs
  where
    f :: (Node a) -> (Node ())
    f (Scalar   _ s) = Scalar () s
    f (Mapping  _ t (mapping)) = Mapping () t (Map.mapKeys f (Map.map f mapping))
    f (Sequence _ t ns) = Sequence () t (P.map f ns)
    f (Anchor   _ id n) = Anchor () id (f n)

