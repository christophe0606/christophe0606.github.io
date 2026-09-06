import VersoBlog
namespace Blog
/-- Minima's original date format, while retaining ISO dates in metadata. -/
def displayDate (iso : String) : String := Id.run do
  let parts := iso.splitOn "-"
  let [year, month, day] := parts | return iso
  let months := #["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  let some m := month.toNat? | return iso
  let some d := day.toNat? | return iso
  let some name := months[m - 1]? | return iso
  return s!"{name} {d}, {year}"

def socialIcon (url : String) : String :=
  if "https://github.com/".isPrefixOf url then "github"
  else if "https://www.linkedin.com/".isPrefixOf url then "linkedin"
  else if "https://vimeo.com/".isPrefixOf url then "vimeo"
  else "mastodon"
end Blog
