import Blog
import Blog.Theme
import Blog.Publish
open Verso Genre Blog Site Syntax

def blog : Site := site Blog.Pages.Home /
  static "assets" ← "static/assets"
  static "static" ← "static/files"
  "about" Blog.Pages.About
  "Gallery" Blog.Pages.Gallery
  "sites" Blog.Pages.Sites
  "arts" Blog.Pages.Arts
  "science" Blog.Pages.Science
  "others" Blog.Pages.Others
  "disclaimer" Blog.Pages.Disclaimer
  "examples" Blog.Pages.Examples
  "404" Blog.Pages.NotFound

def main (args : List String) : IO UInt32 := do
  let result ← blogMain Blog.theme (Blog.withPagination (Blog.withPosts blog)) (options := args)
  if result != 0 then return result
  let destination := outputPath args
  Blog.publishExtras destination
  return 0
where
  outputPath : List String → System.FilePath
    | "--output" :: path :: _ => path
    | _ :: rest => outputPath rest
    | [] => "_site"
