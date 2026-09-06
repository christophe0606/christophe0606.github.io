# My Blog — Lean / Verso

Lean version of my blog

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

#doc (Post) "My new post" =>
%%%
authors := [Blog.config.author]
date := {year := 2026, month := 9, day := 6}
categories := [Blog.arts, Blog.maths, Blog.twoD]
draft := false
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
  registerPost Blog.Posts.MyPost
```

`registerPost` is a small Lean macro that constructs a `RegisteredPost` from the module's Verso document and its `details` declaration. Keep the convention `def Blog.Posts.MyPost.details : Blog.PostDetails` in each post. Missing documents or details are reported during the build.

No changes to `Config.lean` or `Main.lean` are needed. The title, date, and categories come from the post's Verso document. `publicationTime` supplies only the time and timezone; the full Atom/SEO timestamp is derived from the document date. The generated route is derived from Verso's date/title slug. New posts need no `legacyRoute`: listings, SEO, the feed, and the sitemap use the generated route. For migrated posts only, set `legacyRoute := some "arts/2021/10/12/bubbles.html"` to preserve an existing URL. Visibility is controlled only by Verso's `draft`: use `draft := true` to exclude a post from pages, listings, SEO, the feed, and the sitemap; `false` is the default. The internal `publishedAt` function computes the Atom/SEO timestamp from the Verso date and `publicationTime`; it is neither a stored field nor a status setting. Page counts derive from `postsPerPage` automatically.

Categories replace tags entirely. Define reusable categories in `Blog/PostMetadata.lean`; available values are `arts`, `science`, `others`, `maths`, `physics`, `twoD`, `threeD`, and `computerScience`. Set them only in the post's `categories` field. A post may have several categories; Verso generates their category pages and the Atom feed includes each one. The Arts, Science, and Others navigation pages select posts by category membership.

The preview image is optional. Set `image := some "assets/my-picture.jpg"` to use a post-specific sharing image. Otherwise SEO uses `defaultPreviewImage` from `Blog/Config.lean` (the 270×270 `static/root/mstile-150x150.png`) and requests a compact Twitter summary card. The default image is also used for ordinary pages. This does not insert an image into the post body.

Artwork uses `_thumb.jpg` linked to `_signed.jpg`, as in the original. `figure` and standard Markdown images work with local or remote URLs. Use site-relative local paths without a leading slash: Verso inserts a base URL so these also work under a GitHub project subpath.

Vimeo embeds accept an optional positive integer `percent` to scale one player relative to
the `.videowidth` width in `static/files/verso.css`:

```text
:::vimeo "1224367805" "" (percent := 75)
:::
```

Omitting `percent` means `100`, preserving the existing width. `50` halves the width;
`150` makes it 1.5 times as wide. The player stays centered and its height follows the
existing `.video` aspect ratio. The video itself keeps its proportions inside the player.
Use an empty hash string for a public video that has no privacy hash. This option affects
only this post embed, not the gallery.

### Lean code blocks and their options

These examples use this project's **Verso Blog** genre (Verso 4.33.0). Options shown for the Manual genre in Verso's documentation may differ.

Start an example context with an empty `leanInit` block, then use its name after `lean`:

````lean
```leanInit myPost
```

```lean myPost
def twice (n : Nat) : Nat := n + n
```

```lean myPost (name := twiceResult)
#eval twice 21
```

```leanOutput twiceResult
42
```
````

`myPost` is an identifier naming the **shared Lean environment**. Later blocks in that context can use definitions from earlier blocks. Use a different context name for independent examples, and initialize each context once. The context starts with the imports and definitions available in the post's Lean module. Put additional `import` commands at the top of that module, before `#doc`; this version does not support imports inside `leanInit`.

`(name := twiceResult)` instead names the block's **captured diagnostic output**. It does not rename the context, definition, or displayed code block. `leanOutput twiceResult` displays the expected message and checks it during the build: here, the output must match `42`. Name captured outputs uniquely across your examples. A `#eval` block is checked even without `leanOutput`, but a separate output block is how you display its result in the article.

Write options on the opening fence, after the context name, separated by spaces. Named values use `(option := value)`. Boolean options also accept `+option` for `true` and `-option` for `false`:

```text
lean myPost (show := false) (keep := false)
lean myPost -show -keep
```

Those two opening-fence headers are equivalent. There are no commas between options. Context and output names are Lean identifiers, not quoted strings.

| Option on `lean` | Default | Effect |
| --- | --- | --- |
| `(show := false)` or `-show` | `true` | Check the code but omit the block from the rendered page. Useful for setup. |
| `(keep := false)` or `-keep` | `true` | Do not retain the block's environment changes for subsequent blocks. The block can still use earlier definitions. |
| `(name := resultName)` | Unset | Save the block's messages for a `leanOutput resultName` block. |
| `(error := true)` or `+error` | `false` | Require the example to produce a Lean error. The build fails if it unexpectedly succeeds. Changes from an expected-error block are not retained. |
| `(showProofStates := false)` or `-showProofStates` | `true` | Hide rendered proof states while still checking and displaying the proof. |

For example, after the `leanInit myPost` above:

````lean
```lean myPost -show
def answer : Nat := 42
```

```lean myPost -keep (name := temporaryResult)
def temporary : Nat := answer + 1
#eval temporary
```

```leanOutput temporaryResult
43
```

```lean myPost -showProofStates
theorem twice_zero : twice 0 = 0 := by rfl
```

```lean myPost +error
example : Nat := true
```
````

Here, `answer` is available to later blocks despite being hidden; `temporary` is available only inside its block. `+error` checks that an error occurs, not its exact wording; add `(name := ...)` and a `leanOutput` block if you also want to check and show the error message.

Use `leanInit` only to initialize the context; use `lean myPost -show` for hidden declarations or setup commands. For the current implementation and a complete Blog example, see [Verso's code-block option parser](https://github.com/leanprover/verso/blob/v4.33.0/src/verso-blog/VersoBlog.lean) and [its example post](https://github.com/leanprover/verso/blob/v4.33.0/test-projects/website/DemoSite/Blog/Conditionals.lean).

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

Run `lake build` and `lake exe generate-blog` before verification. The verifier reads the compiled registry through `scripts/site-metadata.lean`, so post counts, ordering, URLs, categories, draft status, and pagination come from the current Lean definitions. No Python post list needs updating when you add a post. It also checks local URLs and fragments, artwork hashes, source integrity when the original is available, and page-local three.js inclusion. The original migration inventory is used only for source provenance. Stale draft or pagination files are reported; regenerate into a clean output directory if they remain from an earlier build. It does not validate external links or Vimeo playback. Browser checks additionally confirmed math, checked Lean output, a Vimeo embed, and the three.js canvas. The compatibility converters in `Blog/Math.lean` preserve LaTeX source in plain-text heading titles and prevent Verso 4.33's “Failed to convert” messages for math headings. The displayed headings still use the normal math renderer. The one-time `scripts/import-jekyll.py` records migration provenance and refuses to overwrite edited files; it is not part of `lake build`.

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
