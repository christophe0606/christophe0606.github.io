import Blog.Posts.SolarPhotography
import Blog.Posts.LeanBlog
import Blog.Posts.Hyperbolic
import Blog.Posts.Evolving
import Blog.Posts.Tspart
import Blog.Posts.Schmidtarrangements
import Blog.Posts.Bubbles
import Blog.Posts.Myavatar

open Verso Genre Blog Site Syntax

namespace Blog

structure RegisteredPost where
  document : BlogPost
  details : PostDetails

/-- Build an entry from a post module and its `details` declaration. -/
macro "registerPost " postModule:ident : term => do
  let details := Lean.mkIdentFrom postModule (postModule.getId ++ `details)
  `({ document := { id := (%docName? $postModule), contents := (%doc? $postModule) }
      details := $details : RegisteredPost })

/-- Register each post once. Dates and titles are read from its Verso document. -/
def postRegistry : Array RegisteredPost := #[
  registerPost Blog.Posts.SolarPhotography,
  registerPost Blog.Posts.LeanBlog,
  registerPost Blog.Posts.Hyperbolic,
  registerPost Blog.Posts.Evolving,
  registerPost Blog.Posts.Tspart,
  registerPost Blog.Posts.Schmidtarrangements,
  registerPost Blog.Posts.Bubbles,
  registerPost Blog.Posts.Myavatar
]

/-- Draft documents are excluded from both rendering and publication metadata. -/
def publishedPosts : Array RegisteredPost := postRegistry.filter fun p =>
  p.document.contents.metadata.any (fun m => !m.draft)

def posts : Array PostInfo := publishedPosts.filterMap fun p => do
  let metadata ← p.document.contents.metadata
  let date := metadata.date.toIso8601String
  return {
    toPostDetails := p.details
    title := p.document.contents.titleString
    date := date
    categories := metadata.categories
    route := "blog/" ++ defaultPostName metadata.date p.document.contents.titleString ++ "/"
  }

end Blog
