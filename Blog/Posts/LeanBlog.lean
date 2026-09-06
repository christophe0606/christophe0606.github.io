import Blog.Components
import Blog.PostMetadata
open Verso Genre Blog

def Blog.Posts.LeanBlog.details : Blog.PostDetails where
  publicationTime := "11:11:00+02:00"
  excerpt := "The blog now uses Lean verso"

#doc (Post) "Lean Blog" =>
%%%
authors := [Blog.config.author]
date := {year := 2026, month := 9, day := 6}
categories := [Blog.others]
%%%

I have migrated my blog from Jekyll to the [Lean](https://lean-lang.org) programming language and the [Verso](https://verso.lean-lang.org) documentation framework.

I prefer to use a typechecked programming language to
write my blog.

This also means I can now include Lean proofs and formally verified code directly in my posts :-) I don’t expect to use this feature often, but here’s an example:

```leanInit leanBlog
```

```lean leanBlog +showProofStates
theorem example_identity (n : Nat) : n + 0 = n :=
by simp
```
