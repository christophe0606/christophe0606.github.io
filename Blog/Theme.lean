import Blog.Seo
import Blog.Formatting
open Verso Genre Blog Output Html Template

namespace Blog

private def stylesheetVersion : String := toString (hash (include_str "../static/files/verso.css"))

def theme : Theme := { Theme.default with
  primaryTemplate := do
    let title : String ← param "title"
    let path ← currentPath
    return {{
      <html lang="en" style={{"--blog-math-background: " ++ config.mathBackground}}><head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        {{seoHead title path}}
        {{← builtinHeader}}
        <link rel="stylesheet" href="assets/main.css"/>
        <link rel="stylesheet" href={{"static/verso.css?v=" ++ stylesheetVersion}}/>
      </head><body>
        <header class="site-header" role="banner"><div class="wrapper">
          <a class="site-title" rel="author" href="./">{{config.title}}</a>
          <nav class="site-nav" aria-label="Main navigation">
            <input type="checkbox" id="nav-trigger" class="nav-trigger"/>
            <label for="nav-trigger"><span class="menu-icon">"☰"</span></label>
            <div class="trigger">{{config.navigation.map fun link => {{<a class="page-link" href={{link.url}}>{{link.label}}</a>}}}}</div>
          </nav>
        </div></header>
        <main class="page-content" aria-label="Content"><div class="wrapper">
          {{← param "content"}}
          {{(← param? (α := Html) "posts").getD .empty}}
        </div></main>
        <footer class="site-footer h-card"><div class="wrapper">
          <h2 class="footer-heading">{{config.title}}</h2>
          <div class="footer-col-wrapper"><div class="footer-col footer-col-1">
            <ul class="contact-list"><li class="p-name">{{config.author}}</li></ul>
            <p>{{config.description}}</p>
            <p>"The opinions expressed are my own views and not those of my employer."</p>
            <p><a href="disclaimer/">"disclaimer"</a></p>
          </div><div class="footer-col footer-col-2"><ul class="social-media-list">
            {{config.social.map fun link => {{<li><a rel="me" href={{link.url}}><svg class="svg-icon" aria-hidden="true"><use href={{if socialIcon link.url == "vimeo" then "static/social-icons.svg#vimeo" else "assets/minima-social-icons.svg#" ++ socialIcon link.url}}></use></svg><span class="username">{{link.label}}</span></a></li>}}}}
          </ul></div></div>
        </div></footer>
      </body></html>
    }}
  pageTemplate := do
    let title : String ← param "title"
    pure {{<article class="post">
      {{if title == config.title then .empty else {{<h1 class="post-title">{{title}}</h1>}}}}
      <div class="post-content">{{← param "content"}}</div>
    </article>}}
  postTemplate := do
    let md : Post.Meta ← param "metadata"
    pure {{<article class="post h-entry">
      <header class="post-header"><h1 class="post-title p-name">{{← param "title"}}</h1>
        <p class="post-meta"><time datetime={{md.date.toIso8601String}}>{{displayDate md.date.toIso8601String}}</time></p>
      </header><div class="post-content e-content">{{← param "content"}}</div>
    </article>}}
}
end Blog
