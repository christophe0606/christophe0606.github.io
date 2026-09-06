# My Blog — Lean / Verso

A standalone migration of Christophe Favergeon's Jekyll blog. The original was read as source material; this project does not modify it or need it to build.

## Build and preview

```sh
lake build
lake exe generate-blog
python3 -m http.server 8000 --directory _site
```

Open http://localhost:8000. Output is `_site/`. An alternative destination is supported:

```sh
lake exe generate-blog --output /tmp/my-blog-preview
```

Lean 4.33.1 and Verso v4.33.0 are pinned, matching the supplied example. `lake-manifest.json` locks transitive dependencies. On a fresh checkout, Lake downloads dependencies. This initial workspace has independent copies of the example's dependency cache to avoid unnecessary downloads; it has no symlinks to that example.

## Where to edit

- `Blog/Posts/*.lean`: six published posts, in Verso markup, with checked post metadata.
- `Blog/Config.lean`: site-wide identity, navigation, social links, page size, and styling options.
- `Blog/PostRegistry.lean`: the single list of published post modules, used for rendering, listings, SEO, and the feed.
- `Blog/PostMetadata.lean`: types for per-post editorial fields; the values live in each post file.
- `Blog/Data.lean`: typed gallery pictures, Vimeo videos, and site links, replacing `_data`.
- `Blog/Pages/*.lean`: ordinary pages. `Examples.lean` demonstrates math, checked Lean, video, and three.js; it is available at `/examples/` without adding it to the original navigation.
- `Blog/Components.lean`: reusable Verso directives, replacing the media includes.
- `Blog/Widgets.lean`: listings, pagination, and galleries.
- `Blog/Theme.lean`: header, footer, SEO, and page/post layout.
- `static/assets/`: independent copies of the original images and compiled Minima stylesheet.
- `static/files/verso.css`: small responsive and Verso-specific style adjustments.
- `static/files/scenes/`: page-specific JavaScript modules.
- `Main.lean`: the Verso `Site` declaration and generation entry point.

SEO metadata is generated in `Blog/Seo.lean`: Open Graph, Twitter cards, canonical URLs, JSON-LD, Google verification, icons, and pagination links. `feed.xml` is generated as Atom entirely in Lean; it contains titles, stable URLs, summaries, authors, categories, and publication timestamps.

The two unpublished Jekyll test drafts are preserved as Markdown under `Blog/Drafts`, outside the public site. They are reference sources, not compiled Verso posts. No unpublished content is exposed by the build.

The six old `/arts/YYYY/MM/DD/slug.html` permalinks are generated as full pages with their original fragment IDs, so existing gallery and external links continue working. Verso's `/blog/.../` URLs also work and have canonical links to the old URLs. `Blog/Publish.lean` adds these compatibility pages, configurable pagination, Atom feed, sitemap, root icons, `404.html`, and `.nojekyll`.

The source's prose and mathematics are retained as written (including its original scientific claims). Vimeo privacy hashes are carried into embed URLs. Media still hosted by Vimeo, GitHub, Wikimedia, and the CDN needs network access.

## Author a post

Create `Blog/Posts/MyPost.lean`:

````lean
import Blog.Components
import Blog.PostMetadata
open Verso Genre Blog

def Blog.Posts.MyPost.details : Blog.PostDetails where
  publicationTime := "10:30:00+02:00"
  excerpt := "A short summary of the post."
  image := "assets/my-picture.jpg"
  tags := #["maths", "art"]
  legacyRoute := "arts/2026/09/06/my-post.html"

#doc (Post) "My new post" =>
%%%
authors := [Blog.config.author]
date := {year := 2026, month := 9, day := 6}
categories := [Blog.arts]
%%%

Text with inline math $`x^2 + y^2 = z^2`.

$$`\sum_{n=1}^{N} n = \frac{N(N+1)}{2}`

:::figure "assets/my-picture.jpg" "A useful description"
:::

:::art "assets/my-artwork" "Artwork title"
:::

:::vimeo "264091591" "d7ed240fce"
:::

:::video "assets/my-video.mp4" "assets/my-poster.jpg"
:::

```leanInit myPost
```

```lean myPost
theorem example_identity (n : Nat) : n + 0 = n := by simp
```
````

Import it in `Blog/PostRegistry.lean` and add this entry to `postRegistry` (newest first):

```lean
  ⟨{id := (%docName? Blog.Posts.MyPost), contents := (%doc? Blog.Posts.MyPost)},
    Blog.Posts.MyPost.details⟩
```

No changes to `Config.lean` or `Main.lean` are needed. The title, date, and categories come from the post's Verso document. `publicationTime` supplies only the time and timezone; the full Atom/SEO timestamp is derived from the document date. The generated route is derived from Verso's date/title slug. Supply a unique `legacyRoute` for the stable public URL. Drafts (`draft := true` in the metadata block) are excluded from publication. Page counts derive from `postsPerPage` automatically.

Artwork uses `_thumb.jpg` linked to `_signed.jpg`, as in the original. `figure` and standard Markdown images work with local or remote URLs. Use site-relative local paths without a leading slash: Verso inserts a base URL so these also work under a GitHub project subpath.

## Add a three.js scene

In a post:

```text
:::threeScene "./static/scenes/my-scene.js" "Accessible scene description"
:::
```

Put the module in `static/files/scenes/my-scene.js` and export `mount(element)`. `torus.js` is a working example with resizing, reduced motion support, offscreen rendering suspension, and GPU resource cleanup. Each scene gets its own element, so a page can have several scenes.

The directive emits a module import in the containing page only. It deliberately does not register `jsFiles`, because Verso collects those at site scope. Ordinary pages neither include nor request the three.js loader or library. The example pins three.js 0.180.0; move the module and dependencies into `static/files` if offline use is needed.

Components use Verso's `block_component +directive` mechanism. Prefer it for further plugins; HTML attributes and strings are escaped by the HTML DSL. JavaScript module paths are encoded as string literals.

## Verify

```sh
python3 scripts/verify-site.py
```

Checks local URLs and fragments, artwork hashes, source integrity when the original is available, pagination, draft exclusion, and page-local three.js inclusion. It does not validate external links or Vimeo playback. Browser checks additionally confirmed math, checked Lean output, a Vimeo embed, and the three.js canvas. Verso 4.33 emits three informational plain-text conversion messages for the mathematical headings in Schmidt Arrangements; those headings render correctly (30 math expressions, zero KaTeX errors on that page). The one-time `scripts/import-jekyll.py` records migration provenance and refuses to overwrite edited files; it is not part of `lake build`.

## GitHub Pages

The workflow in `.github/workflows/pages.yml` builds and uploads `_site`. In repository Settings → Pages, select GitHub Actions. The workflow deploys on pushes to `main` or manual dispatch. Change the branch filter if needed. The copied `static/root/CNAME` retains `www.favergeon.info`; remove or change it, together with `Blog.config.url`, if deploying to a different domain. No deployment has been performed as part of this migration.

Reference: [Verso websites](https://verso.lean-lang.org/doc/latest/Websites/) and [Verso extensions](https://verso.lean-lang.org/doc/latest/Extensions/).

## Prepare new artwork with Python

Run manually from this project:

```sh
uv run scripts/prepare_images.py /path/to/picture.jpg
```

Creates `picture_gallery.jpg`, `picture_signed.jpg`, and `picture_thumb.jpg` beside the input using the original notebook's watermark. The input stays unchanged. Add `--output-dir static/assets/YYYY-MM-DD` to write into the blog's assets, or `--overwrite` to replace existing generated versions.

See [image preparation](scripts/IMAGE_PREPARATION.md) for dimensions, opacity/placement options, the Mathematica mapping, and tests. This is independent of the Lean build.

## Math appearance

Set `mathBackground` in `Blog/Config.lean` to `"#eee"` (gray, the default),
`"#fff"` (white), or another CSS color. This applies to both inline and display
equations. Display equations use a single padded block with horizontal scrolling
when necessary. Rebuild with `lake exe generate-blog` after changing the setting.
