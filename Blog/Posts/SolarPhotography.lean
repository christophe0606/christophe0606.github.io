import Blog.Components
import Blog.PostMetadata

open Verso Genre Blog

def Blog.Posts.SolarPhotography.details : Blog.PostDetails where
  publicationTime := "12:00:00+02:00"
  excerpt := "Solar photographs from September 4, 2026, a prominence video, and a look at SunTracker."
  image := some "assets/2026-09-06/sun_2026_09_04_13_05_54_g140_e4_00003_stratawarp_31pct_thumb.jpg"

#doc (Post) "Solar Photography" =>
%%%
authors := [Blog.config.author]
date := {year := 2026, month := 9, day := 6}
categories := [Blog.science]
draft := false
%%%

I have recently bought a solar telescope for solar photography.
A solar telescope is a very special kind of telescope : it contains a very narrowband
filter that only allows a very narrow range of wavelengths of light to pass through, typically centered on the hydrogen-alpha line.
This makes it possible to observe the Sun's chromosphere and prominences in great detail.

# SunTracker

I have developed a custom software on my Mac to track the sun for making timelapse.
It uses computer vision techniques to detect the solar limb and adjust the telescope's position accordingly, ensuring that the Sun remains centered in the frame throughout the recording session.
It is tricky because of atmospheric turbulence, which can cause the solar image to shift and blur, making precise tracking challenging.
Also, there are not a lot of high constrast features on the solar disk, which makes it difficult for the tracking algorithm to maintain accurate positioning.

The screenshot below shows SunTracker during a recording session, with a selected region over the solar limb and the recording and mosaic controls alongside the preview.

:::figure "assets/2026-09-06/suntracker.jpeg" "SunTracker recording interface with a selected region on the solar limb"
:::

Here are two photographs of the Sun from September 4, 2026, together with a video of a solar prominence.

# The solar disk

Dark filaments cross the bright disk, while prominences extend beyond its edge.

:::anchor "solar-disk"
:::

:::art "assets/2026-09-06/sun_2026_09_04_13_05_54_g140_e4_00003_stratawarp_31pct" "The solar disk on September 4, 2026"
:::

# A closer look

This closer view shows a prominence above the solar limb and the texture of the disk below it.

:::anchor "prominence-photo"
:::

:::art "assets/2026-09-06/sun_2026_09_04_13_23_50_g285_e5_00001_stratawarp_10f" "A solar prominence on September 4, 2026"
:::

# Prominence video

:::anchor "prominence-video"
:::

:::vimeo "1224367805" "" (percent := 140)
:::
