{- YParse.hs

   Copyright 2021 Bo Joel Svensson & Yinan Yu 
-} 

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
import qualified Coppe.Tinylang.AbsTinylang as Tiny
import qualified Coppe.Tinylang.PrintTinylang as Tiny
import Coppe.Tinylang.EvalTinylang

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
--                 "input_layer" -> Just Input
                 "annotated"   -> decodeAnnotated m
                 "reference"   -> decodeReference m
                 _ -> decodeIngredient m
                

decodeReference :: Map.Map (Node Pos) (Node Pos) -> Maybe Recipe
decodeReference m =
  case parseEither ((m .: "name") :: Parser Text) of
    Left (pos,str) -> Nothing
    Right n -> Just $ NamedRecipe (unpack n)

decodeIngredient :: Map.Map (Node Pos) (Node Pos) -> Maybe Recipe
decodeIngredient m =
  do
    name  <- decodeName m      
    annot <- case decodeAnnot m of
               Nothing -> Just Map.empty
               Just a  -> Just a
    hyps    <- decodeParams m
    trnable <- decodeTrainable m
    trans   <- decodeTransform m

    case parseTiny (unpack trans) of
      Left (ParseError s) -> Nothing
      Right e -> return $ Operation $ Ingredient (unpack name) annot hyps trnable e

decodeTrainable :: Map.Map (Node Pos) (Node Pos) -> Maybe Bool
decodeTrainable m =
  case parseEither ((m .: "trainable") :: Parser Bool) of
    Left (pos,str) -> Nothing
    Right b -> Just b

decodeTransform :: Map.Map (Node Pos) (Node Pos) -> Maybe Text
decodeTransform m =
  case parseEither ((m .: "transform") :: Parser Text) of
    Left (pos, str) -> Nothing
    Right t -> Just t

    
decodeName :: Map.Map (Node Pos) (Node Pos) -> Maybe Text
decodeName m =
  case parseEither ((m .: "type") :: Parser Text) of
    Left (pos,str) -> Nothing
    Right t        -> Just t

decodeAnnot :: Map.Map (Node Pos) (Node Pos) -> Maybe Annotation
decodeAnnot m =
  case parseEither ((m .: "annotation") :: Parser (Node Pos)) of
    Left (pos, str) -> Nothing
    Right a         -> decodeAnnotationNode a


decodeParams :: Map.Map (Node Pos) (Node Pos) -> Maybe HyperMap
decodeParams m = case parseEither (( m .: "parameters") :: Parser (Node Pos)) of
                   Left (pos, str) -> Nothing
                   Right p         -> decodeParameterNode p

decodeParameterNode :: Node Pos -> Maybe HyperMap
decodeParameterNode (Mapping _ _ m) = case decodeParameterList ls of
                                        Just ls' -> Just $ Map.fromList ls'
                                        Nothing -> Nothing
  where
    ls = Map.toList m
    decodeParameterList :: [(Node Pos, Node Pos)] -> Maybe [(String, Parameter)]
    decodeParameterList [] = Nothing
    decodeParameterList ((k,v):xs) =
      case (decodeKey k, decodeParameter v) of
        (Just k', Just p') -> Just [(unpack k', p')]
                                    
        _ -> Nothing
decodeParameterNode n = error $ "Parameters are not a mapping:" ++ show n

decodeParameter :: Node Pos -> Maybe Parameter
decodeParameter (Mapping _ _ m) =
  case elts of
    [(Just "integer",n)] -> case parseEither ((parseYAML n) :: Parser Integer) of
                              Left _ -> Nothing
                              Right i -> Just $ ValParam $ IntVal i
    [(Just "float", f)]  -> case parseEither ((parseYAML f) :: Parser Double) of
                              Left _ -> Nothing
                              Right f -> Just $ ValParam $ FloatVal f
    [(Just "string", s)] -> case parseEither ((parseYAML s) :: Parser Text) of
                              Left _ -> Nothing
                              Right s -> Just $ ValParam $ StringVal (unpack s)
    [(Just "list", l)]   -> case decodeValueList l of
                              Nothing -> Nothing
                              Just v  -> Just $ ValParam $ ListVal v
    [(Just "function", f)] -> case decodeFunctionValue f of
                                Nothing -> Nothing
                                Just f' -> Just $ f'
    _ -> Nothing -- Malformed value 

  where elts = Map.toList (Map.mapKeys decodeKey m)
decodeParameter _ = Nothing
-- decodeParameter (Sequence _ _ s)  = error $ "it is a sequence ????: " ++ show s

decodeFunctionValue :: Node Pos -> Maybe Parameter
decodeFunctionValue = error "this is a function value. todo"

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
decodeAnnotationNode (Mapping _ _ m) = decodeAnnotation m 
decodeAnnotationNode _ = Nothing -- malformed annotation

decodeAnnotation :: Map.Map (Node Pos) (Node Pos) -> Maybe Annotation
decodeAnnotation m = case decodeAnnotationList ls of
                       Nothing -> Nothing
                       Just as -> Just $ Map.fromList as
  where
    ls = Map.toList m
    decodeAnnotationList :: [(Node Pos, Node Pos)] -> Maybe [(String, Value)]
    decodeAnnotationList [] = Nothing
    decodeAnnotationList ((k,v):xs) =
      case (decodeKey k, decodeValue v) of
        (Nothing, _) -> decodeAnnotationList xs
        (_, Nothing) -> decodeAnnotationList xs
        (Just k',Just v') -> case decodeAnnotationList xs of
                               Nothing -> Just [(unpack k',v')]
                               Just as -> Just $ (unpack k',v') : as

decodeValue :: Node Pos -> Maybe Value
decodeValue (Mapping _ _ m) =   -- This mapping should be just one key/value pair
  case elts of
    [(Just "integer",n)] -> case parseEither ((parseYAML n) :: Parser Integer) of
                              Left _ -> Nothing
                              Right i -> Just $ IntVal i
    [(Just "float", f)]  -> case parseEither ((parseYAML f) :: Parser Double) of
                              Left _ -> Nothing
                              Right f -> Just $ FloatVal f
    [(Just "string", s)] -> case parseEither ((parseYAML s) :: Parser Text) of
                              Left _ -> Nothing
                              Right s -> Just $ StringVal (unpack s)
    [(Just "list", l)]   -> case decodeValueList l of
                              Nothing -> Nothing
                              Just v  -> Just $ ListVal v
    _ -> Nothing -- Malformed value 

  where elts = Map.toList (Map.mapKeys decodeKey m)

decodeValueList :: Node Pos -> Maybe [Value]
decodeValueList (Sequence _ _ s) = if (P.length res > P.length res')
                                   then Nothing
                                   else (Just res')
  where res = P.map decodeValue s
        res' = catMaybes res

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
    -- encodeRecipe' Input = Just $ mapping [ "type" .= ("input_layer" :: Text) ]
    encodeRecipe' (Seq rs) = Just $ encodeRecipeList rs
    encodeRecipe' (NamedRecipe n) = Just $ mapping [ "type" .= (pack "reference"), "name" .= (pack n) ]
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
                  [ "parameters" .= mapping (encodeHyper (hyper i)),
                    "trainable"  .= (trainable i),
                    "transform"  .= pack (Tiny.printTree (transform i))] )
  where m = mapping pairs
        pairs = (encodeAnnotation (annotation i))

encodeHyper :: HyperMap -> [Pair] 
encodeHyper m = Map.foldrWithKey (\k v ps -> (pack k .= encodeParam v):ps) [] m

encodeParam :: Parameter -> Node ()
encodeParam (FunAppParam f a) = encodeFunApp f a
encodeParam (ValParam p) = encodeValue p

encodeFunApp :: Function -> Arguments -> Node ()
encodeFunApp (NamedFun s) args = mapping $ ["function" .= (pack s)] ++
                                            case args' of
                                              Nothing -> []
                                              Just n  -> ["arguments" .= n] -- sequence (not sure about that)
  where args' = encodeArguments args
  
encodeArguments :: [(Maybe String, Parameter)] -> Maybe [Pair]
encodeArguments [] = Nothing
encodeArguments ((n,p):args) =
  let args' = encodeArguments args
  in 
    let h = case n of
              Nothing ->
                [ "arg" .= encodeParam p ]
              Just n' ->
                [ "name" .= (pack n'), "arg" .= encodeParam p ]
    in case args' of
         Nothing -> Just h
         Just hs -> Just (h ++ hs)
                                 

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

