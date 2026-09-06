import Blog.Components
open Verso Genre Blog

#doc (Page) "Writing with Verso" =>
This page demonstrates reusable features for new posts.

# Mathematics

Inline mathematics: $`e^{i\pi}+1=0`.

$$`\int_0^\infty \frac{x^3}{e^x-1}\,dx=\frac{\pi^4}{15}`

# Checked Lean code

```leanInit examples
```

```lean examples
def twice (n : Nat) : Nat := n + n

theorem twice_eq (n : Nat) : twice n = 2 * n := by
  simp [twice, Nat.two_mul]
```

```lean examples (name := result)
#eval twice 21
```

```leanOutput result
42
```

# Images and video

:::art "assets/2021-10-09/MyAvatarBraids" "Selfie"
:::

:::vimeo "264091591" "d7ed240fce"
:::

# Interactive three.js

The following module is loaded only by pages that use this component.

:::threeScene "./static/scenes/torus.js" "A rotating torus knot"
:::
