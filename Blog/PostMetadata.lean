import Blog.Config

namespace Blog

def arts : Verso.Genre.Blog.Post.Category := ⟨"Arts", "arts"⟩

/-- Editorial fields kept beside each post's native Verso metadata. -/
structure PostDetails where
  /-- Time and timezone only; the date comes from the Verso metadata block. -/
  publicationTime : String := "00:00:00Z"
  excerpt : String
  image : String
  tags : Array String := #[]
  legacyRoute : String

/-- Derived data for listings, SEO, feeds, and stable public URLs. -/
structure PostInfo extends PostDetails where
  title : String
  date : String
  published : String
  category : String
  route : String

end Blog
