module Coppe.EvalTinylang where

import Coppe.TinyLang.AbsTinylang
import Coppe.AST

import Data.Maybe
import qualified Data.Map as Map
import Control.Monad.State

{- Planning Tinylang

- A tinylang program can refer to any of parameters
  in the hyperparameter map by name. 
- A tinylang program can refer to any of the annotations
  in the annotation map by name.
- Should there be a way to tell those namespaces apart?

-} 

data EvalState = EvalState HyperMap Annotation (Map.Map String Value)

type Eval a = State EvalState a

lookup :: String -> Eval (Maybe Value)
lookup s =
  do
    (EvalState h a e) <- get
    let r = case Map.lookup s h of
              Just (ValParam v) -> Just v
              _ -> case Map.lookup s a of
                     Just v -> Just v
                     _ -> case Map.lookup s e of
                            Just v -> Just v
                            _ -> Nothing
    return r

addBinding :: String -> Value -> Eval ()
addBinding s v =
  do
    (EvalState h a e) <- get
    let e' = Map.insert s v e
    put (EvalState h a e')

-- Top level lambda is applied to the argument value
-- If that does not result in a value there program is "incorrect" 
evalTiny :: HyperMap -> Annotation -> Exp -> Value -> Eval Value
evalTiny = undefined 
