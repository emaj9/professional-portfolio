{-# LANGUAGE OverloadedStrings #-}
module Main where

import Hakyll
import System.FilePath
import Data.Text ( unpack )
import Text.Pandoc
import Data.Monoid ( (<>) )
-- import qualified Data.HashMap as M
import qualified Data.HashMap.Lazy as M
import Data.Aeson ( Value(..) )

--hakyll :: Rules () -> IO ()

ctx = defaultContext
applyDefaultTemplate = loadAndApplyTemplate "templates/default.html"

getPCs :: MonadMetadata m => Identifier -> m [String]
getPCs identifier = do
    metadata <- getMetadata identifier
    let unsafeString (String s) = unpack s
    return $ maybe [] (map trim . splitAll "," . unsafeString) $ M.lookup "PC" metadata

main :: IO ()
main = hakyll $ do
  tags <- buildTags "lessons/*" (fromCapture "tags/*.html")
  pc <- buildTagsWith getPCs "lessons/*" (fromCapture "pc/*.html")

  tagsRules tags $ \tag pattern -> do
    let title = "Lessons about " ++ tag
    route idRoute
    compile $ do
      lessons <- loadAll pattern
      let ctx' =
            constField "title" title <>
            listField "lessons" ctx (pure lessons) <>
            ctx

      makeItem ""
        >>= loadAndApplyTemplate "templates/tag.html" ctx'
        >>= applyDefaultTemplate ctx'
        >>= relativizeUrls

  tagsRules pc $ \pc pattern -> do
    let title = "Lessons using " ++ pcTitle pc
    route idRoute
    compile $ do
      lessons <- loadAll pattern
      let ctx' =
            constField "title" title <>
            listField "lessons" ctx (pure lessons) <>
            ctx

      makeItem ""
        >>= loadAndApplyTemplate "templates/tag.html" ctx'
        >>= applyDefaultTemplate ctx'
        >>= relativizeUrls

  match "pages/subjects.md" $ do
    route $ customRoute myRoute
    compile $ do
      getResourceBody
        >>= renderPandoc
        -- >>= applyAsTemplate (listField "tags" defaultContext (loadAll "tags/*.html") <> defaultContext)
        >>= applyDefaultTemplate defaultContext

  match "lessons/*.md" $ do
    route $ setExtension "html"
    compile $ pandocCompiler
      >>= applyDefaultTemplate defaultContext

  match "pages/*" $ do
  -- match :: Pattern -> Rules () -> Rules ()
    route $ customRoute myRoute
    -- route :: route -> Rules ()
    -- customRoute:: (indentifer -> Filepath) -> route
    compile $ pandocCompiler
    -- compile :: Compiler () -> Rules ()
      >>= loadAndApplyTemplate "templates/default.html" (defaultContext <> linesInPages)
      >>= relativizeUrls

  match "templates/*" $ compile templateCompiler

  match "img/*" $ do
    route idRoute
    compile copyFileCompiler

  match "lessons/pdf/*" $ do
    route idRoute
    compile copyFileCompiler

  match "pdf/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/style.css" $ do
    route idRoute
    compile copyFileCompiler

  match "audio/*" $ do
    route idRoute
    compile copyFileCompiler

linesInPages :: Context String
linesInPages = field "n" f where
  f :: (Item String -> Compiler String)
  f i = do
   return $ show $ length $ lines $ itemBody i

myRoute :: (Identifier -> FilePath)
myRoute id
  | id == "pages/home.html" = "index.html"
  | otherwise = drop 6 $ dropExtension (toFilePath id) ++ ".html"

pcTitle x = "Professional Competency " ++ drop 3 x
