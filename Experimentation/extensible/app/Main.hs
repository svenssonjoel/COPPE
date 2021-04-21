
{-# Language GADTs #-}
--{-# Language DataKinds #-}
--{-# Language KindSignatures #-}
--{-# Language ExistentialQuantification #-}
--{-# Language ScopedTypeVariables #-}

module Main where

import Data.List

-- User privileges for our users
-- data UserPrivilege = Member | Admin | Guest

data Member = Member
data Admin  = Admin
data Guest  = Guest


-- Our type witness
data WitnessPrivilege up where
 WitnessMember :: WitnessPrivilege Member
 WitnessGuest  :: WitnessPrivilege Guest
 WitnessAdmin  :: WitnessPrivilege Admin

-- data family WitnessPrivilege up

-- data instance WitnessPrivilege Member = WitnessMember
-- data instance WitnessPrivilege Guest  = WitnessGuest
-- data instance WitnessPrivilege Admin  = WitnessAdmin

  
-- Our user type
data User up = User
  { userId :: Integer
  , userName :: String
  , userPrivilege :: WitnessPrivilege up
  }


-- The type that we use to hide the privilege type variable
data SomeUser where
  SomeUser :: User a -> SomeUser

-- A function that accept a user id (Integer), and reads
-- the corresponding user from the database. Note that the return
-- type level privilege is hidden in the return value `SomeUser`.
readUser :: Integer -> IO SomeUser
readUser userId = pure $ case find ((== userId) . (\(a, _, _) -> a)) dbRows of
  Just (id_, name_, type_) ->
    case type_ of
      "member" -> SomeUser (User id_ name_ WitnessMember)
      "guest" -> SomeUser (User id_ name_ WitnessGuest)
      "admin" -> SomeUser (User id_ name_ WitnessAdmin)
  Nothing -> error "User not found"

-- This is a function that does not care
-- about user privilege
getUserName :: User up -> String
getUserName = userName

-- This is a function only allows user
-- with Admin privilege.
deleteStuffAsAdmin :: User Admin -> IO ()
deleteStuffAsAdmin _ = pure ()

main :: IO ()
main = do
  (SomeUser user) <- readUser 12

  putStrLn $ getUserName user -- We don't care about user privilege here

  case userPrivilege user of -- But here we do.
    -- So we bring the type-level user privilege in scope by matching
    -- on `userPrivilege` field and then GHC knows that `user`
    -- is actually `User 'Admin`, and so we can call `deleteStuffAsAdmin`
    -- with `user`.
    WitnessAdmin ->
      deleteStuffAsAdmin user
    _ -> error "Need admin user"

dbRows :: [(Integer, String, String)]
dbRows =
  [ (10, "John", "member")
  , (11, "alice", "guest")
  , (12, "bob", "admin")
  ]
