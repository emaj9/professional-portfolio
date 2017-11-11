{-# LANGUAGE OverloadedStrings #-}
module Main where

import Hakyll
import System.FilePath
import Text.Pandoc
import Data.Monoid ( (<>) )

--hakyll :: monad -> IO ()

main :: IO ()
main = hakyll $ do
  match "pages/*" $ do
    route $ customRoute myRoute
    compile $ pandocCompiler
      >>= loadAndApplyTemplate "templates/default.html" defaultContext
      >>= relativizeUrls
  match "templates/*" $ compile templateCompiler
  match "css/style.css" $ do
    route idRoute
    compile copyFileCompiler

myRoute :: (Identifier -> FilePath)
myRoute id
  | id == "pages/home.html" = "index.html"
  | otherwise = dropExtension (toFilePath id) ++ ".html"
