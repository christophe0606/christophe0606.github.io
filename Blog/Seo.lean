import Blog.PostRegistry
import Blog.Config
open Lean Verso Output Html

namespace Blog

/-- Serialize structured data with a JSON encoder, also protecting the HTML script boundary. -/
def structuredData (title description route image : String) (post : Option PostInfo) : String :=
  let person := Lean.Json.mkObj [("@type", "Person"), ("name", toJson config.author)]
  let fields := [
    ("@context", toJson ("https://schema.org" : String)),
    ("@type", toJson (if post.isSome then "BlogPosting" else "WebSite")),
    ("author", person),
    ("description", toJson description),
    ("headline", toJson title),
    ("image", toJson image),
    ("name", toJson config.title),
    ("publisher", Lean.Json.mkObj [("@type", "Organization"), ("name", toJson config.author),
      ("logo", Lean.Json.mkObj [("@type", "ImageObject"), ("url", toJson (config.url ++ "/" ++ config.logo))])]),
    ("sameAs", toJson config.sameAs),
    ("url", toJson (config.url ++ "/" ++ route))]
  let fields := match post with
    | none => fields
    | some p => fields ++ [("datePublished", toJson p.published), ("dateModified", toJson p.published),
        ("mainEntityOfPage", toJson (config.url ++ "/" ++ route))]
  (Lean.Json.mkObj fields).compress.replace "<" "\\u003c" |>.replace ">" "\\u003e" |>.replace "&" "\\u0026"

/-- SEO and discovery metadata, equivalent to the original Jekyll SEO include. -/
def seoHead (title : String) (path : Array String) : Html := Id.run do
  let post := posts.find? (fun p => p.title == title)
  let description := post.map (·.excerpt) |>.getD config.description
  let route := post.map (·.legacyRoute) |>.getD (String.intercalate "/" path.toList ++ if path.isEmpty then "" else "/")
  let image := config.url ++ "/" ++ (post.map (·.image) |>.getD config.logo)
  let count := (posts.size + max 1 config.postsPerPage - 1) / max 1 config.postsPerPage
  let page : Nat := if path.isEmpty then 1 else
    if path.size == 1 then (path[0]!.drop 4).toString.toNat?.getD 0 else 0
  let pageUrl := fun n => config.url ++ if n == 1 then "/" else s!"/page{n}/"
  return {{
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <title>{{title}} " | " {{if title == config.title then config.description else config.title}}</title>
    <meta name="generator" content="Lean Verso"/>
    <meta name="author" content={{config.author}}/>
    <meta name="description" content={{description}}/>
    <meta property="og:title" content={{title}}/>
    <meta property="og:locale" content={{config.locale}}/>
    <meta property="og:description" content={{description}}/>
    <meta property="og:site_name" content={{config.title}}/>
    <meta property="og:image" content={{image}}/>
    <meta property="og:type" content={{if post.isSome then "article" else "website"}}/>
    <link rel="canonical" href={{config.url ++ "/" ++ route}}/>
    <meta property="og:url" content={{config.url ++ "/" ++ route}}/>
    {{match post with
      | none => .empty
      | some p => {{<meta property="article:published_time" content={{p.published}}/>}}}}
    {{if page > 1 then {{<link rel="prev" href={{pageUrl (page - 1)}}/>}} else .empty}}
    {{if page > 0 && page < count then {{<link rel="next" href={{pageUrl (page + 1)}}/>}} else .empty}}
    <meta name="twitter:card" content="summary_large_image"/>
    <meta property="twitter:image" content={{image}}/>
    <meta property="twitter:title" content={{title}}/>
    <meta name="google-site-verification" content={{config.googleSiteVerification}}/>
    <script type="application/ld+json">{{.text false (structuredData title description route image post)}}</script>
    <link type="application/atom+xml" rel="alternate" href={{config.url ++ "/feed.xml"}} title={{config.title}}/>
    <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png?v=1"/>
    <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png?v=1"/>
    <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png?v=1"/>
    <link rel="manifest" href="site.webmanifest?v=1"/>
    <link rel="mask-icon" href="safari-pinned-tab.svg?v=1" color="#5bbad5"/>
    <meta name="msapplication-TileColor" content="#da532c"/>
    <meta name="theme-color" content="#ffffff"/>
  }}

end Blog
