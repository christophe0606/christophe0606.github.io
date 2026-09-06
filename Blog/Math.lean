import VersoBlog

open Lean Lean.Doc.Syntax Verso.Doc.Elab

namespace Blog

/-- Preserve math source in plain-text headings and previews (Verso 4.33 fallback). -/
@[inline_to_string Lean.Doc.Syntax.inline_math]
meta def inlineMathToString : InlineToString
  | _, `(inline| \math code( $s )) => some s.getString
  | _, _ => none

@[inline_to_string Lean.Doc.Syntax.display_math]
meta def displayMathToString : InlineToString
  | _, `(inline| \displaymath code( $s )) => some s.getString
  | _, _ => none

end Blog
