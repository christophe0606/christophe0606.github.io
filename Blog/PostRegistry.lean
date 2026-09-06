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

/-- Register each post once. Dates and titles are read from its Verso document. -/
def postRegistry : Array RegisteredPost := #[
  ⟨{id := (%docName? Blog.Posts.Hyperbolic), contents := (%doc? Blog.Posts.Hyperbolic)},
    Blog.Posts.Hyperbolic.details⟩,
  ⟨{id := (%docName? Blog.Posts.Evolving), contents := (%doc? Blog.Posts.Evolving)},
    Blog.Posts.Evolving.details⟩,
  ⟨{id := (%docName? Blog.Posts.Tspart), contents := (%doc? Blog.Posts.Tspart)},
    Blog.Posts.Tspart.details⟩,
  ⟨{id := (%docName? Blog.Posts.Schmidtarrangements), contents := (%doc? Blog.Posts.Schmidtarrangements)},
    Blog.Posts.Schmidtarrangements.details⟩,
  ⟨{id := (%docName? Blog.Posts.Bubbles), contents := (%doc? Blog.Posts.Bubbles)},
    Blog.Posts.Bubbles.details⟩,
  ⟨{id := (%docName? Blog.Posts.Myavatar), contents := (%doc? Blog.Posts.Myavatar)},
    Blog.Posts.Myavatar.details⟩
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
    published := date ++ "T" ++ p.details.publicationTime
    category := String.intercalate ", " (metadata.categories.map (·.slug))
    route := "blog/" ++ defaultPostName metadata.date p.document.contents.titleString ++ "/"
  }

end Blog
