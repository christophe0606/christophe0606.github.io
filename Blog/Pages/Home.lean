import Blog.Widgets
open Verso Genre Blog

def homeHtml := Blog.homePosts 1

#doc (Page) "My Blog" =>
:::blob homeHtml
:::
