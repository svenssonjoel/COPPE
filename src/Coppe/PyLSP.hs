{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Coppe.PyLSP where

import System.Process
import GHC.IO.Handle as IO

import Data.Aeson
import GHC.Generics
import Data.Text as T
import Data.ByteString.Lazy.Char8 as BLC

import Prelude as P

data ClientInfo = ClientInfo { name_ :: String,
                               version :: String }
  deriving (Generic, Show)

type URI = String

data InitOptions = InitOptions
  deriving (Generic, Show)

data ClientCapabilities = ClientCapabilities {test :: Integer }
  deriving (Generic, Show)

data WorkspaceFolder = WorkspaceFolder { uri :: URI, name :: String }
  deriving (Generic, Show)

data IntializeRequest = IntializeRequest { processId :: Maybe Integer,
                                           clientInfo :: ClientInfo,
                                           locale :: String,
                                           rootPath :: Maybe String,
                                           rootUri :: Maybe URI,
                                           initializationOptions :: InitOptions,
                                           capabilities :: ClientCapabilities,
                                           workspaceFolders :: [WorkspaceFolder] }
  deriving (Generic, Show)

instance ToJSON WorkspaceFolder where
  toEncoding = genericToEncoding defaultOptions

instance ToJSON IntializeRequest where
  toEncoding = genericToEncoding defaultOptions

instance ToJSON ClientCapabilities where
  toEncoding = genericToEncoding defaultOptions

instance ToJSON ClientInfo where
  toJSON (ClientInfo n v) = object ["name" .= (T.pack n) , "version" .= (T.pack v)]

instance ToJSON InitOptions where
  toEncoding = genericToEncoding defaultOptions


data Message where
  Message :: ToJSON a => a -> String -> Message

instance ToJSON Message where
  toJSON (Message a s) = object ["jsonrpc" .= ("2.0" :: Text), "id" .= ("1" :: Text), "method" .= s,  "params" .= toJSON a]


testinit = Message init "initialize"
  where init = IntializeRequest Nothing (ClientInfo "apa" "1.2") "en" Nothing Nothing InitOptions (ClientCapabilities 15) [WorkspaceFolder "This_is_an_uri" "This_is_a_name"]



startPyLSP :: IO (Maybe Handle, Maybe Handle, Maybe Handle, ProcessHandle)
startPyLSP = createProcess (proc "pylsp" ["--verbose","--debug"]){ std_out = CreatePipe, std_in = CreatePipe, std_err = CreatePipe}


-- testReq = "Content-Length: ...\r\n\r\n \"jsonrpc\": \"2\"id\": 1,\"method\": \"textDocument/didOpen\",\"params\": {}}\r\n" 

mkReq :: String -> String
mkReq s = "Content-Length: " ++ show (P.length s) ++ "\r\n\r\n" ++ s

  

testReq = mkReq "{ \"jsonrpc\": \"2.0\",\"id\" : 1,\"method\": \"textDocument/definition\",\"params\": { \"textDocument\": { \"uri\": \"file:///py/test.py\" },\"position\": {\"line\": 0,\"character\": 0 } } }"
-- "{\"jsonrpc\": \"2\"id\": 1,\"method\": \"textDocument/didOpen\",\"params\": {}}\r\n" 


testPyLSP :: IO ()
testPyLSP =
  do (Just input, Just output, Just err, pid) <- startPyLSP
     IO.hPutStr input testReq
     P.putStrLn testReq
     str <- IO.hGetContents output
     errstr <- IO.hGetContents err
     P.putStrLn "**** ERROR ****"
     P.putStrLn errstr
     P.putStrLn "**** Output ****"
     P.putStrLn str
     

     
     
                                 
     










