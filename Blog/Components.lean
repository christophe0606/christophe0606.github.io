import Blog.Math

open Verso Genre Blog Output Html

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

block_component +directive vimeo (videoId : String) (hash : String) where
  toHtml _ _ _ _ _ := pure {{
    <div class="videowidth"><div class="video">
      <iframe src={{"https://player.vimeo.com/video/" ++ videoId ++ "?h=" ++ hash}}
        title="Vimeo video" loading="lazy" allow="fullscreen; picture-in-picture" allowfullscreen="allowfullscreen"></iframe>
    </div></div>
  }}

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
