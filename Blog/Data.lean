import Blog.Config

namespace Blog

structure GalleryImage where
  post : String
  url : String

structure GalleryVideo where
  post : String
  videoId : String
  hash : String
  title : String

def gallery : Array GalleryImage := #[
  ⟨"blog/2026-9-6-solar-photography/#solar-disk", "assets/2026-09-06/sun_2026_09_04_13_05_54_g140_e4_00003_stratawarp_31pct_gallery.jpg"⟩,
  ⟨"blog/2026-9-6-solar-photography/#prominence-photo", "assets/2026-09-06/sun_2026_09_04_13_23_50_g285_e5_00001_stratawarp_10f_gallery.jpg"⟩,
  ⟨"arts/2021/10/09/myavatar.html#selfie", "assets/2021-10-09/MyAvatarBraids_gallery.jpg"⟩,
  ⟨"arts/2021/10/09/myavatar.html#sephora", "assets/2021-10-09/SephoraBraids_gallery.jpg"⟩,
  ⟨"arts/2021/10/09/myavatar.html#face", "assets/2021-10-09/face_gallery.jpg"⟩,
  ⟨"arts/2021/10/12/bubbles.html#YinYangFlat", "assets/2021-10-12/YinYanCircle_gallery.jpg"⟩,
  ⟨"arts/2021/10/12/bubbles.html#YinYangBubble", "assets/2021-10-12/YinYangBubble_gallery.jpg"⟩,
  ⟨"arts/2021/10/12/bubbles.html#Sephora", "assets/2021-10-12/SephoraBubble_gallery.jpg"⟩,
  ⟨"arts/2021/10/12/bubbles.html#Anina", "assets/2021-10-12/Anina_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1A", "assets/2021-10-13/Minus1A_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1B", "assets/2021-10-13/Minus1B_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1C", "assets/2021-10-13/Minus1C_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1D", "assets/2021-10-13/Minus1D_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1E", "assets/2021-10-13/Minus1E_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1G", "assets/2021-10-13/Minus1G_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1H", "assets/2021-10-13/Minus1H_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1I", "assets/2021-10-13/Minus1I_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1J", "assets/2021-10-13/Minus1J_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus1K", "assets/2021-10-13/Minus1K_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus3A", "assets/2021-10-13/Minus3A_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus3B", "assets/2021-10-13/Minus3B_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus3C", "assets/2021-10-13/Minus3C_gallery.jpg"⟩,
  ⟨"arts/2021/10/13/schmidtarrangements.html#Minus15A", "assets/2021-10-13/Minus15A_gallery.jpg"⟩,
  ⟨"arts/2021/10/16/tspart.html#trefoil", "assets/2021-10-16/TrefoilKnot_gallery.jpg"⟩,
  ⟨"arts/2021/10/28/evolving.html#sierpinski", "assets/2021-10-28/Pyramid_gallery.jpg"⟩,
  ⟨"arts/2023/02/11/hyperbolic.html#trianglegroup", "assets/2023-02-11/TriangleGroup_gallery.jpg"⟩,
  ⟨"arts/2023/02/11/hyperbolic.html#withpattern", "assets/2023-02-11/WithPattern_gallery.jpg"⟩
]

def videos : Array GalleryVideo := #[
  ⟨"blog/2026-9-6-solar-photography/#prominence-video", "1224367805", "", "Solar Photography"⟩,
  ⟨"arts/2023/02/11/hyperbolic.html#EscherTiling", "742171245", "8da470eed1", "Hyperbolic Tilings"⟩,
  ⟨"arts/2023/02/11/hyperbolic.html#HyperbolicPlane", "797924461", "2e4ccabe7d", "Hyperbolic Tilings"⟩,
  ⟨"arts/2023/02/11/hyperbolic.html#Mobius", "797925763", "41912c45cb", "Hyperbolic Tilings"⟩,
  ⟨"arts/2021/10/09/myavatar.html#VideoBraid", "629920741", "8c1c133e17", "My Avatar"⟩,
  ⟨"arts/2021/10/12/bubbles.html#VideoCircle", "629924483", "80d25b38ba", "Bubbles"⟩,
  ⟨"arts/2021/10/16/tspart.html#sephora", "633559314", "74bc63acba", "TSP Art"⟩
]

def sites : Array NavLink := #[
  ⟨"John D. Cook", "https://www.johndcook.com/blog/"⟩
]

end Blog
