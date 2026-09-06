import Blog.Components
import Blog.PostMetadata

open Verso Genre Blog

def Blog.Posts.Bubbles.details : Blog.PostDetails where
  publicationTime := "10:05:32+02:00"
  excerpt := "How to generate circle packings from pictures."
  image := some "assets/2021-10-12/SephoraBubble_thumb.jpg"
  legacyRoute := some "arts/2021/10/12/bubbles.html"

#doc (Post) "Bubbles" =>

%%%
authors := [Blog.config.author]
date := {year := 2021, month := 10, day := 12}
categories := [Blog.arts, Blog.maths, Blog.twoD, Blog.threeD]
%%%

In this post, I'd like to explain how I have created pictures like this Yin Yang symbol :


:::anchor "YinYangFlat"
:::


:::art "assets/2021-10-12/YinYanCircle" "YinYang"
:::


It is starting with the [distance transform](https://en.wikipedia.org/wiki/Distance_transform) using an Euclidean distance.

To see how it works, let's apply this distance transform to a white rectangle on a black background:


:::figure "assets/2021-10-12/Rectangle.jpg" "Rectangle"
:::


We get the following result:


:::figure "assets/2021-10-12/DistanceTransform.jpg" "Distance transform"
:::


Each pixel is giving the distance to the closer obstacle.
So, if at a pixel we put a circle with radius given by the pixel value, then this circle will only touch the closest obstacle.

For instance, if we select the center pixel on the previous image we get:


:::figure "assets/2021-10-12/CircleInRect.jpg" "Circle in rectangle"
:::


We see that the red circle is touching the sides of the square.

The algorithm is thus :

* Computing the edges of a picture ;

* Applying the distance transform ;

* Starting with the bigger circles and trying to place them ;

* Continuing until all the circles have been placed.

When placing a new circle, we must check that it is not overlapping with a circle already placed on the picture. 

If it is overlapping, its radius is decreased. One input of the algorithm is a list of radius to use when decreasing the radius of the overlapping circles.

Once we have this list of circles, we can generate the final picture. Different stylings can be used to draw the circles.

And it is how the Yin Yang picture was generated.

We can also generate 3D pictures:


:::anchor "YinYangBubble"
:::


:::art "assets/2021-10-12/YinYangBubble" "YinYang 3D"
:::


It also work well on photos. But the edge detection is the tricky part. Some filtering may be needed.


:::anchor "Anina"
:::


:::art "assets/2021-10-12/Anina" "Anina"
:::

(Thanks to [Anina](https://anina.typepad.com) for allowing me to use the photo.)

Vivid colors are giving very nice results:


:::anchor "Sephora"
:::


:::art "assets/2021-10-12/SephoraBubble" "Sephora"
:::


And it is also possible to apply the algorithm to a video with interesting results:


:::anchor "VideoCircle"
:::


:::vimeo "629924483" "80d25b38ba"
:::


Thanks to [Sephora Venites](https://www.sephoravenites.com/) to allow me to use some photos and videos for experimenting with my algorithms.
