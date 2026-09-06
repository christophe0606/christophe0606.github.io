import VersoBlog

namespace Blog

structure NavLink where
  label : String
  url : String

structure SiteConfig where
  title : String
  author : String
  description : String
  url : String
  logo : String
  /-- CSS background color for inline and display math; use "#fff" for white. -/
  mathBackground : String := "#eee"
  locale : String := "en_US"
  googleSiteVerification : String := "aPGEGimqqR-phz1VpA2ng7D5ORBS6ctNJE8r-eVFtv4"
  sameAs : Array String := #["https://github.com/christophe0606",
    "https://www.linkedin.com/in/favergeon", "https://ello.co/cfavergeon",
    "https://vimeo.com/cfavergeon", "https://mathstodon.xyz/@christophef"]
  postsPerPage : Nat := 5
  showExcerpts : Bool := true
  navigation : Array NavLink
  social : Array NavLink

def config : SiteConfig where
  title := "My Blog"
  mathBackground := "#eee"
  author := "Christophe Favergeon"
  description := "Blog about science and algorithmic art."
  url := "https://www.favergeon.info"
  logo := "apple-touch-icon.png"
  navigation := #[⟨"ARTS", "arts/"⟩, ⟨"GALLERY", "Gallery/"⟩, ⟨"OTHERS", "others/"⟩,
    ⟨"SCIENCE", "science/"⟩, ⟨"ABOUT", "about/"⟩, ⟨"SITES", "sites/"⟩]
  social := #[⟨"christophe0606", "https://github.com/christophe0606"⟩,
    ⟨"favergeon", "https://www.linkedin.com/in/favergeon"⟩,
    ⟨"cfavergeon", "https://vimeo.com/cfavergeon"⟩,
    ⟨"christophef", "https://mathstodon.xyz/@christophef"⟩]

end Blog
