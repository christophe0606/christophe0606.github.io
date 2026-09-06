import Blog.PostRegistry

open Lean Verso Genre Blog

/-- Read the compiled registry for verification without duplicating post metadata in Python. -/
def main : IO Unit := do
  let registered ← Blog.postRegistry.mapM fun entry => do
    let some metadata := entry.document.contents.metadata
      | throw (IO.userError s!"Post has no metadata: {entry.document.contents.titleString}")
    let route := "blog/" ++ defaultPostName metadata.date entry.document.contents.titleString ++ "/"
    return Json.mkObj [
      ("title", toJson entry.document.contents.titleString),
      ("route", toJson route),
      ("publicRoute", toJson (entry.details.legacyRoute.getD route)),
      ("draft", toJson metadata.draft),
      ("publishedAt", toJson (metadata.date.toIso8601String ++ "T" ++ entry.details.publicationTime)),
      ("categories", toJson (metadata.categories.map (·.slug)))]
  IO.println (Json.mkObj [
    ("url", toJson Blog.config.url),
    ("postsPerPage", toJson (max 1 Blog.config.postsPerPage)),
    ("sameAs", toJson Blog.config.sameAs),
    ("posts", toJson registered)]).compress
