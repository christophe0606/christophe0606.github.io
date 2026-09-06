import Blog.Widgets
import Blog.Pages.Home
import Blog.Posts

open Verso Genre Blog Output

namespace Blog

/-- Render the same registry used by listings, SEO, and feeds. -/
def withPosts : Site → Site
  | .page id page dirs => .page id page (dirs.push
      (.blog "blog" (%docName? Blog.Posts) (%doc? Blog.Posts)
        (publishedPosts.map (·.document))))
  | site => site

/-- Add pagination from the configured page size, without hand-maintained pages. -/
def withPagination : Site → Site
  | .page id page dirs => Id.run do
    let size := max 1 config.postsPerPage
    let count := (posts.size + size - 1) / size
    let pages := (List.range (count - 1)).toArray.map fun i =>
      let n := i + 2
      let content : Doc.Part Page := {
        title := #[.text config.title]
        titleString := config.title
        metadata := none
        subParts := #[]
        content := #[.other (.blob (homePosts n)) #[]]
      }
      Dir.page s!"page{n}" (.str `Blog.Pagination (toString n)) content #[]
    return .page id page (dirs ++ pages)
  | site => site

def xmlEscape (s : String) : String :=
  s.replace "&" "&amp;" |>.replace "<" "&lt;" |>.replace ">" "&gt;" |>.replace "\"" "&quot;"

/-- Retain old Jekyll permalinks as complete pages (including fragment anchors). -/
def publishExtras (destination : System.FilePath) : IO Unit := do
  for entry in ← System.FilePath.readDir "static/root" do
    IO.FS.writeBinFile (destination / entry.fileName) (← IO.FS.readBinFile entry.path)
  for post in posts do
    let some legacyRoute := post.legacyRoute | continue
    let source := destination / post.route / "index.html"
    let target := destination / legacyRoute
    IO.FS.createDirAll target.parent.get!
    let html ← IO.FS.readFile source
    -- Verso URLs are relative to its base element; legacy paths are four levels deep.
    let html := html.replace "<base href=\"../.././\"" "<base href=\"../../../.././\""
    IO.FS.writeFile target html
  IO.FS.writeFile (destination / "404.html")
    ((← IO.FS.readFile (destination / "404/index.html")).replace "<base href=\".././\"" "<base href=\"./\"")
  IO.FS.writeFile (destination / ".nojekyll") ""
  let items := posts.toList.map fun p =>
    let url := xmlEscape (config.url ++ "/" ++ p.publicRoute)
    "<entry><title>" ++ xmlEscape p.title ++ "</title><link href=\"" ++ url ++ "\"/>" ++
    "<id>" ++ url ++ "</id><published>" ++ p.publishedAt ++ "</published><updated>" ++ p.publishedAt ++
    "</updated><author><name>" ++ xmlEscape config.author ++ "</name></author>" ++
    String.join (p.categories.map fun category => "<category term=\"" ++ xmlEscape category.slug ++ "\"/>") ++
    "<summary type=\"html\">" ++ xmlEscape p.excerpt ++ "</summary></entry>"
  let updated := posts[0]?.map (·.publishedAt) |>.getD "1970-01-01T00:00:00Z"
  IO.FS.writeFile (destination / "feed.xml") (
    "<?xml version=\"1.0\" encoding=\"utf-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\">" ++
    "<generator uri=\"https://verso.lean-lang.org/\">Lean Verso</generator><title>" ++ xmlEscape config.title ++
    "</title><subtitle>" ++ xmlEscape config.description ++ "</subtitle><link href=\"" ++ xmlEscape config.url ++
    "/feed.xml\" rel=\"self\" type=\"application/atom+xml\"/><link href=\"" ++ xmlEscape config.url ++
    "/\" rel=\"alternate\" type=\"text/html\"/><id>" ++ xmlEscape config.url ++ "/feed.xml</id><updated>" ++
    updated ++ "</updated><author><name>" ++ xmlEscape config.author ++ "</name></author>" ++ String.join items ++ "</feed>")
  let routes := #["", "about/", "Gallery/", "arts/", "science/", "others/", "sites/", "disclaimer/"] ++ posts.map (·.publicRoute)
  IO.FS.writeFile (destination / "sitemap.xml") (
    "<?xml version=\"1.0\" encoding=\"utf-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">" ++
    String.join (routes.toList.map fun r => "<url><loc>" ++ config.url ++ "/" ++ r ++ "</loc></url>") ++ "</urlset>")
  IO.FS.writeFile (destination / "robots.txt") ("User-agent: *\nAllow: /\nSitemap: " ++ config.url ++ "/sitemap.xml\n")

end Blog
