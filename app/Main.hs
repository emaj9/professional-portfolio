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


ctx = defaultContext
applyDefaultTemplate = loadAndApplyTemplate "templates/default.html"

getPCs :: MonadMetadata m => Identifier -> m [String]
getPCs identifier = do
    metadata <- getMetadata identifier
    let unsafeString (String s) = unpack s
    return $ maybe [] (map trim . splitAll "," . unsafeString) $ M.lookup "PC" metadata

main :: IO ()
main = hakyll $ do

  match "templates/*" $ compile templateCompiler

  -- PAGES --------------------
  match "pages/music-blog.md" $ do
      route $ constRoute "music-blog.html"
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let mostRecent = head posts

        let indexCtx =
                listField "posts" postCtx (return posts) <>
                ctx

        getResourceBody
            >>= applyAsTemplate indexCtx
            >>= loadAndApplyTemplate "templates/default.html" indexCtx
            >>= relativizeUrls

  match "pages/*" $ do
  -- match :: Pattern -> Rules () -> Rules ()
    route $ customRoute myRoute
    -- route :: route -> Rules ()
    -- customRoute:: (indentifer -> Filepath) -> route
    compile $ pandocCompiler
    -- compile :: Compiler () -> Rules ()
      >>= loadAndApplyTemplate "templates/default.html" (defaultContext <> linesInPages)
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

  -- POSTS ---------------------------

  match "posts/*" $ do
    route $ setExtension "html"
    compile $ pandocMathCompiler
      >>= loadAndApplyTemplate "templates/post.html"  postCtx
      >>= saveSnapshot "content"
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

  -- STATIC CONTENT -------------------
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

postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y" <>
  ctx

pandocMathCompiler :: Compiler (Item String)
pandocMathCompiler
  = pandocCompilerWith readerOptions writerOptions where
    readerOptions = defaultHakyllReaderOptions
    writerOptions = defaultHakyllWriterOptions
      { writerHTMLMathMethod = MathJax ""
      }
