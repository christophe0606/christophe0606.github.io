import Blog.PostRegistry
import Blog.Data
import Blog.Formatting

open Verso Genre Blog Output Html

namespace Blog

def postList (items : Array PostInfo) : Html := {{
  <ul class="post-list">{{items.map fun p => {{
    <li><span class="post-meta">{{displayDate p.date}} " - " {{p.category}}</span>
      <h3><a class="post-link" href={{p.legacyRoute}}>{{p.title}}</a></h3>
      {{if config.showExcerpts then {{<p>{{p.excerpt}}</p>}} else .empty}}
    </li>
  }}}}</ul>
}}

def homePosts (page : Nat) : Html := Id.run do
  let size := max 1 config.postsPerPage
  let count := (posts.size + size - 1) / size
  let first := (page - 1) * size
  return {{
    <div class="home"><h2 class="post-list-heading">"Posts"</h2>
      {{postList (posts.extract first (first + size))}}
      <nav class="pagination" aria-label="Pagination">
        {{(List.range count).toArray.map fun i =>
          let n := i + 1
          let url := if n == 1 then "./" else s!"page{n}/"
          if n == page then {{<em aria-current="page">{{toString n}}</em>}}
          else {{<a href={{url}}>{{toString n}}</a>}}}}
      </nav>
      <p class="rss-subscribe">"subscribe "<a href="feed.xml">"via RSS"</a></p>
    </div>
  }}

def galleryHtml : Html := {{
  <h2>"Videos"</h2>
  <div class="video-gallery">{{videos.map fun v => {{
    <div class="videobox"><div class="video">
      <iframe src={{"https://player.vimeo.com/video/" ++ v.videoId ++ "?h=" ++ v.hash}}
        title={{v.title}} loading="lazy" allow="fullscreen; picture-in-picture" allowfullscreen="allowfullscreen"></iframe>
      </div><a class="videolink" href={{v.post}}>"Post: "{{v.title}}</a>
    </div>
  }}}}</div>
  <h2>"Pictures"</h2>
  <div class="image-gallery">{{gallery.map fun img => {{
    <div class="box"><a href={{img.post}}><img src={{img.url}} class="img-gallery" alt="Algorithmic artwork" loading="lazy"/></a></div>
  }}}}</div>
}}

def sitesHtml : Html := {{<ul>{{sites.map fun s => {{<li><a href={{s.url}}>{{s.label}}</a></li>}}}}</ul>}}

def artsHtml := postList (posts.filter (·.category == "arts"))

end Blog
