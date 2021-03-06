-- | Parsing of structs.
module GI.GIR.Struct
    ( Struct(..)
    , parseStruct
    ) where

import Data.Text (Text)

import GI.GIR.Field (Field, parseFields)
import GI.GIR.Method (Method, MethodType(..), parseMethod)
import GI.GIR.Parser

data Struct = Struct {
    structIsBoxed :: Bool,
    structTypeInit :: Maybe Text,
    structSize :: Int,
    gtypeStructFor :: Maybe Name,
    -- https://bugzilla.gnome.org/show_bug.cgi?id=560248
    structIsDisguised :: Bool,
    structFields :: [Field],
    structMethods :: [(Name, Method)],
    structDeprecated :: Maybe DeprecationInfo }
    deriving Show

parseStruct :: Parser (Name, Struct)
parseStruct = do
  name <- parseName
  deprecated <- parseDeprecation
  structFor <- queryAttrWithNamespace GLibGIRNS "is-gtype-struct-for" >>= \case
               Just t -> (fmap Just . qualifyName) t
               Nothing -> return Nothing
  typeInit <- queryAttrWithNamespace GLibGIRNS "get-type"
  disguised <- optionalAttr "disguised" False parseBool
  fields <- parseFields
  constructors <- parseChildrenWithLocalName "constructor" (parseMethod Constructor)
  methods <- parseChildrenWithLocalName "method" (parseMethod OrdinaryMethod)
  return (name,
          Struct {
            structIsBoxed = error ("[boxed] unfixed struct " ++ show name)
          , structTypeInit = typeInit
          , structSize = error ("[size] unfixed struct " ++ show name)
          , gtypeStructFor = structFor
          , structIsDisguised = disguised
          , structFields = fields
          , structMethods = constructors ++ methods
          , structDeprecated = deprecated
          })
