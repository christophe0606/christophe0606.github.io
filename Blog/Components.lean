import Blog.Math

open Verso Genre Blog Output Html
open Verso.Doc.Elab Lean

namespace Blog

/-- A full resolution artwork behind the original thumbnail. -/
block_component +directive art (path : String) (title : String) where
  toHtml _ _ _ _ _ := pure {{
    <a class="figure" href={{path ++ "_signed.jpg"}}>
      <img class="art" src={{path ++ "_thumb.jpg"}} alt={{title}} title={{title}} loading="lazy"/>
    </a>
  }}

block_component +directive figure (url : String) (title : String) where
  toHtml _ _ _ _ _ := pure {{
    <div class="figure"><img src={{url}} alt={{title}} title={{title}} loading="lazy"/></div>
  }}

block_component +directive anchor (name : String) where
  toHtml _ _ _ _ _ := pure {{<span id={{name}}></span>}}

block_component vimeo (videoId : String) (hash : String) (percent : Nat) where
  toHtml _ _ _ _ _ := pure {{
    <div class="videowidth"><div class="video" style={{s!"width: {percent}%; left: 50%; transform: translateX(-50%);"}}>
      <iframe src={{"https://player.vimeo.com/video/" ++ videoId ++ (if hash.isEmpty then "" else "?h=" ++ hash)}}
        title="Vimeo video" loading="lazy" allow="fullscreen; picture-in-picture" allowfullscreen="allowfullscreen"></iframe>
    </div></div>
  }}

/-- Scale one Vimeo player relative to the width set by `.videowidth`. -/
structure VimeoArgs where
  videoId : String
  hash : String
  percent : Nat

instance : Verso.ArgParse.FromArgs VimeoArgs DocElabM where
  fromArgs := VimeoArgs.mk <$>
    .positional `videoId .string <*>
    .positional `hash .string <*>
    ((·.getD 100) <$> .named `percent .nat true)

@[directive vimeo]
def vimeoDirective : DirectiveExpanderOf VimeoArgs
  | args, blocks => do
    if args.percent == 0 then
      throwError "Vimeo percent must be greater than zero"
    ``(vimeo $(Lean.quote args.videoId) $(Lean.quote args.hash) $(Lean.quote args.percent)
      #[$(← blocks.mapM Verso.Doc.Elab.elabBlock),*])

/-- Native video; the browser fetches metadata only when requested. -/
block_component +directive video (url : String) (poster : String) where
  toHtml _ _ _ _ _ := pure {{
    <video controls="controls" preload="none" poster={{poster}} src={{url}}>
      <a href={{url}}>"Download video"</a>
    </video>
  }}

/-- Load an ES module only on pages containing this component.
The module exports mount(element); use separate modules for different scenes.
Do not use jsFiles: Verso collects those dependencies across the site. -/
block_component +directive threeScene (sceneModule : String) (description : String) where
  toHtml id _ _ _ _ := do
    pure {{
      <div class="three-scene" id={{id}} role="img" aria-label={{description}}>
        <p>{{description}}</p>
      </div>
      <script type="module">{{.text false (
        "const el = document.getElementById(" ++ (toString id).quote ++ ");\n" ++
        "import(" ++ sceneModule.quote ++ ").then(m => m.mount(el)).catch(error => { el.textContent = 'The 3D scene could not load: ' + error.message; });")}}</script>
    }}

end Blog
