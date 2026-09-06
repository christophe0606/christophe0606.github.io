import Blog.Components
import Blog.PostMetadata

open Verso Genre Blog

def Blog.Posts.Evolving.details : Blog.PostDetails where
  publicationTime := "04:59:00+02:00"
  excerpt := "Representing in 3D the different steps of an L-system recursion"
  image := some "assets/2021-10-28/Pyramid_thumb.jpg"
  legacyRoute := some "arts/2021/10/28/evolving.html"

#doc (Post) "Evolving L-system" =>

%%%
authors := [Blog.config.author]
date := {year := 2021, month := 10, day := 28}
categories := [Blog.arts, Blog.maths, Blog.twoD, Blog.threeD]
%%%

An [L-system](https://en.wikipedia.org/wiki/L-system) is a rewriting system where some rules are describing how symbols are replaced by string of symbols.

The system is starting with an initial string which is expanded by application of the rewriting rules.

When the symbols are encoding some movements (translation or rotation) then we can generate pictures.

For instance, let's consider the rules:

* A -> B-A-B

* B -> A+B+A 

and the initial string is "A".

If "A" and "B" are representing a translation by one unit, "+" is representing a rotation by 60 degrees and "-" is representing a rotation by -60 degrees, then we get the folllowing strings and pictures.

# 1st iteration 

The generated string is B-A-B (the first rule was applied to the starting string "A")


:::figure "assets/2021-10-28/Level1.jpg" "Level1"
:::


# 2nd iteration

The generated string is A+B+A-B-A-B-A+B+A

:::figure "assets/2021-10-28/Level2.jpg" "Level2"
:::


# 3rd iteration

The generated string is B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B


:::figure "assets/2021-10-28/Level3.jpg" "Level3"
:::


# 4th iteration

The generated string is A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A


:::figure "assets/2021-10-28/Level4.jpg" "Level4"
:::


# 5th iteration 

The generated string is B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B+A+B+A-B-A-B-A+B+A+B-A-B+A+B+A+B-A-B-A+B+A-B-A-B-A+B+A-B-A-B+A+B+A+B-A-B


:::figure "assets/2021-10-28/Level5.jpg" "Level5"
:::


# Stacking of the iterations

Now, I'd like to represent in 3D those iterations. I can just stack the pictures and create a mesh:


:::figure "assets/2021-10-28/Sierpinski3D.jpg" "Sierpinski3D"
:::


It is not very beautiful but it can be smoothed and some thickness added to the walls. The new result is:


:::figure "assets/2021-10-28/SierpinskiSmoothed3D.jpg" "SierpinskiSmoothed3D"
:::


Finally, it can be 3D printed:


:::anchor "sierpinski"
:::


:::art "assets/2021-10-28/Pyramid" "Sierpinski"
:::

