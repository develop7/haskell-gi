module GI.Attributes
    ( genAllAttributes
    ) where

#if !MIN_VERSION_base(4,8,0)
import Control.Applicative ((<$>))
#endif
import Control.Monad (forM_)
import qualified Data.Set as S
import Data.Text (Text)

import GI.API
import GI.Code
import GI.SymbolNaming
import GI.Util (lcFirst)

-- A list of distinct property names for all GObjects appearing in the
-- given list of APIs.
findObjectPropNames :: [(Name, API)] -> CodeGen [Text]
findObjectPropNames apis = S.toList <$> go apis S.empty
    where
      go :: [(Name, API)] -> S.Set Text -> CodeGen (S.Set Text)
      go [] set = return set
      go ((_, api):apis) set =
        case api of
          APIInterface iface ->
              go apis $ insertProps (ifProperties iface) set
          APIObject object ->
              go apis $ insertProps (objProperties object) set
          _ -> go apis set

      insertProps :: [Property] -> S.Set Text -> S.Set Text
      insertProps props set = S.union set ((S.fromList . map propName) props)

genPropertyAttr :: Text -> CodeGen ()
genPropertyAttr pName = group $ do
  line $ "-- Property \"" <> pName <> "\""
  let name = hyphensToCamelCase  pName
  line $ "_" <> lcFirst name <> " :: Proxy \"" <> pName <> "\""
  line $ "_" <> lcFirst name <> " = Proxy"
  exportToplevel ("_" <> lcFirst name)

genAllAttributes :: [(Name, API)] -> CodeGen ()
genAllAttributes allAPIs = do
  setLanguagePragmas ["DataKinds"]
  setModuleFlags [ImplicitPrelude, NoTypesImport, NoCallbacksImport]

  line $ "import Data.Proxy (Proxy(..))"
  blank

  propNames <- findObjectPropNames allAPIs
  forM_ propNames $ \name -> do
      genPropertyAttr name
      blank
