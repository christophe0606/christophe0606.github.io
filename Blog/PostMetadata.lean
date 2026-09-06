import Blog.Config

namespace Blog

def arts : Verso.Genre.Blog.Post.Category := ⟨"Arts", "arts"⟩
def science : Verso.Genre.Blog.Post.Category := ⟨"Science", "science"⟩
def others : Verso.Genre.Blog.Post.Category := ⟨"Others", "others"⟩
def maths : Verso.Genre.Blog.Post.Category := ⟨"Maths", "maths"⟩
def physics : Verso.Genre.Blog.Post.Category := ⟨"Physics", "physics"⟩
def twoD : Verso.Genre.Blog.Post.Category := ⟨"2D", "2d"⟩
def threeD : Verso.Genre.Blog.Post.Category := ⟨"3D", "3d"⟩
def computerScience : Verso.Genre.Blog.Post.Category := ⟨"Computer Science", "computer-science"⟩

/-- Editorial fields kept beside each post's native Verso metadata. -/
structure PostDetails where
  /-- Time and timezone only; the date comes from the Verso metadata block. -/
  publicationTime : String := "00:00:00Z"
  excerpt : String
  /-- Optional site-relative sharing image; otherwise use the site default. -/
  image : Option String := none
  /-- Optional URL retained for posts migrated from another site. -/
  legacyRoute : Option String := none

/-- Derived data for listings, SEO, feeds, and stable public URLs. -/
structure PostInfo extends PostDetails where
  title : String
  date : String
  categories : List Verso.Genre.Blog.Post.Category
  route : String

/-- Compute the Atom/SEO timestamp from the Verso date and the editorial time. -/
def PostInfo.publishedAt (post : PostInfo) : String :=
  post.date ++ "T" ++ post.publicationTime

/-- Prefer a migrated URL when supplied; otherwise use Verso's generated route. -/
def PostInfo.publicRoute (post : PostInfo) : String :=
  post.legacyRoute.getD post.route

end Blog
