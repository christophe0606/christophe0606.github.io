#!/usr/bin/env python3
"""One-time, read-only importer for this blog. Normal builds use only Lean sources.
Run only in an empty destination: existing authored files are never overwritten.
"""
from pathlib import Path
import re, json, shutil, hashlib, sys
SRC = Path(sys.argv[1] if len(sys.argv)>1 else '/Users/cfavergeon/Documents/Development/favergeon/blog')
ROOT = Path(__file__).resolve().parents[1]
def put(path, text):
    p=ROOT/path
    if p.exists():
        if p.read_text() == text: return
        raise SystemExit(f'Refusing to overwrite {p}')
    p.parent.mkdir(parents=True, exist_ok=True); p.write_text(text)
def q(s): return json.dumps(str(s), ensure_ascii=False)
def fields(text):
    return dict(re.findall(r'^ *([\w]+):[^\S\n]*(.*?)[^\S\n]*$',text,re.M))
def val(s): return s.strip().strip('"').strip("'")
def front(p):
    _, f, body=p.read_text().split('---',2)
    return {k:val(v) for k,v in fields(f).items()},body.strip()
def convert(body):
    def inc(m):
        kind=m[1]; a=dict(re.findall(r'(\w+)="([^"]*)"',m[2]))
        if kind=='art': args=[a['name'].lstrip('/'),a['title']]
        elif kind=='figure': args=[a['url'].lstrip('/') if a['url'].startswith('/') else a['url'],a['title']]
        elif kind=='vimeo': args=[a['content'],a['h']]
        else: raise ValueError(kind)
        return '\n:::'+kind+' '+' '.join(map(q,args))+'\n:::\n'
    body=re.sub(r'{% include (\w+)\.html(.*?)%}',inc,body)
    body=re.sub(r'<a name="([^"]+)"></a>',lambda m:'\n:::anchor '+q(m[1])+'\n:::\n',body)
    body=re.sub(r'\$\$(.*?)\$\$',lambda m:'$$`'+m[1].strip()+'`',body,flags=re.S)
    body=re.sub(r'(?<!\$)\$(?![\$`])(.*?)(?<!\$)\$(?!\$)',lambda m:'$`'+m[1]+'`',body)
    # Verso requires whitespace before lists.
    body=re.sub(r'([^\n])\n(?=\* )',r'\1\n\n',body)
    # All source headings become sections under the post title.
    body=re.sub(r'^#{1,6} ', '# ', body,flags=re.M)
    return body
posts=[]
for p in sorted((SRC/'_posts').glob('*.md')):
    f,body=front(p)
    draft=f.get('published')=='false'
    if draft:
        # Preserve unpublished originals separately; no draft is added to the public site.
        put('Blog/Drafts/'+p.name, p.read_text()); continue
    date=f['date'].split()[0]; y,m,d=map(int,date.split('-'))
    slug=p.stem[11:]; module=slug[:1].upper()+slug[1:]
    posts.append(dict(f,module=module,slug=slug,date=date,old=f"arts/{y:04}/{m:02}/{d:02}/{slug}.html",route=f"blog/{y}-{m}-{d}-"+re.sub('[^a-z0-9 -]','',f['title'].lower()).replace(' ','-')+'/'))
    put('Blog/Posts/'+module+'.lean',f'import Blog.Components\nimport Blog.Config\n\nopen Verso Genre Blog\n\n#doc (Post) {q(f["title"])} =>\n\n%%%\nauthors := [Blog.config.author]\ndate := {{year := {y}, month := {m}, day := {d}}}\ncategories := [Blog.arts]\n%%%\n\n'+convert(body)+'\n')
posts.reverse()
config='''import VersoBlog

namespace Blog

structure NavLink where
  label : String
  url : String

structure SiteConfig where
  title : String
  author : String
  description : String
  url : String
  logo : String
  postsPerPage : Nat := 5
  showExcerpts : Bool := true
  navigation : Array NavLink
  social : Array NavLink
  deriving Inhabited

def config : SiteConfig where
  title := "My Blog"
  author := "Christophe Favergeon"
  description := "Blog about science and algorithmic art."
  url := "https://www.favergeon.info"
  logo := "apple-touch-icon.png"
  navigation := #[⟨"ARTS", "arts/"⟩, ⟨"GALLERY", "Gallery/"⟩, ⟨"OTHERS", "others/"⟩,
    ⟨"SCIENCE", "science/"⟩, ⟨"ABOUT", "about/"⟩, ⟨"SITES", "sites/"⟩]
  social := #[⟨"christophe0606", "https://github.com/christophe0606"⟩,
    ⟨"favergeon", "https://www.linkedin.com/in/favergeon"⟩,
    ⟨"cfavergeon", "https://vimeo.com/cfavergeon"⟩,
    ⟨"christophef", "https://mathstodon.xyz/@christophef"⟩]

def arts : Verso.Genre.Blog.Post.Category := ⟨"Arts", "arts"⟩

/-- Extra editorial metadata, corresponding to Jekyll front matter. -/
structure PostInfo where
  title : String
  date : String
  category : String
  excerpt : String
  image : String
  tags : Array String
  route : String
  legacyRoute : String

def posts : Array PostInfo := #[
'''
config+=',\n'.join('  { title := '+q(p['title'])+', date := '+q(p['date'])+', category := "arts",\n    excerpt := '+q(p['excerpt'])+', image := '+q(p['image'].lstrip('/'))+',\n    tags := #['+', '.join(q(t.strip()) for t in p['tags'].strip('[]').split(','))+'],\n    route := '+q(p['route'])+', legacyRoute := '+q(p['old'])+' }' for p in posts)
config+='\n]\n\nend Blog\n'
# Inhabited unnecessary for config with nested types.
config=config.replace('  deriving Inhabited\n','')
put('Blog/Config.lean',config)
def entries(name):
    text=(SRC/'_data'/name).read_text()
    return [fields(s) for s in re.split(r'^- ',text,flags=re.M)[1:]]
data='''import Blog.Config

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
'''
data+=',\n'.join('  ⟨'+q(x['post'].lstrip('/'))+', '+q(x['url'].lstrip('/'))+'⟩' for x in entries('gallery.yml'))+'\n]\n\ndef videos : Array GalleryVideo := #[\n'
data+=',\n'.join('  ⟨'+', '.join(q(x[k].lstrip('/') if k=='post' else x[k]) for k in ['post','content','h','title'])+'⟩' for x in entries('videos.yml'))+'\n]\n\ndef sites : Array NavLink := #[\n'
data+=',\n'.join('  ⟨'+q(x['name'])+', '+q(x['url'])+'⟩' for x in entries('blogs.yml'))+'\n]\n\nend Blog\n'
put('Blog/Data.lean',data)
f,b=front(SRC/'about.md')
b=b.replace('{% avatar christophe0606 size=50 %}', '![Christophe Favergeon](https://github.com/christophe0606.png?size=50)')
put('Blog/Pages/About.lean','import Blog.Components\n\nopen Verso Genre Blog\n\n#doc (Page) "About" =>\n\n'+convert(b)+'\n')
f,b=front(SRC/'disclaimer.html')
b=b.replace('{% include email.html %}',(SRC/'_includes/email.html').read_text())
b=b.replace('{{site.title}}','"# ++ Blog.config.title ++ r#"').replace('{{site.url | absolute_url}}','"# ++ Blog.config.url ++ r#"')
put('Blog/Pages/Disclaimer.lean','import Blog.Config\nopen Verso Genre Blog Output\n\ndef disclaimerHtml : Html := .text false (r#"'+b+'"#)\n\n#doc (Page) "Disclaimer" =>\n\n:::blob disclaimerHtml\n:::\n')
put('Blog/Posts.lean','\n'.join('import Blog.Posts.'+p['module'] for p in posts)+'\n\nopen Verso Genre Blog\n\n#doc (Page) "Posts" =>\n')
shutil.copytree(SRC/'assets',ROOT/'static/assets',ignore=shutil.ignore_patterns('.DS_Store','*.scss'))
shutil.copy2(SRC/'_site/assets/main.css',ROOT/'static/assets/main.css')
(ROOT/'static/root').mkdir()
for p in SRC.iterdir():
    if p.is_file() and (p.suffix in ['.png','.svg','.xml','.webmanifest'] or p.name in ['CNAME','google6d9c71355863f158.html']): shutil.copy2(p,ROOT/'static/root'/p.name)
manifest={str(p.relative_to(SRC)):hashlib.sha256(p.read_bytes()).hexdigest() for p in SRC.rglob('*') if p.is_file() and not any(x in p.parts for x in ['.git','.sass-cache'])}
put('scripts/source-checksums.json',json.dumps(manifest,indent=2)+'\n')
put('scripts/migration-inventory.json',json.dumps({'source':str(SRC),'posts':posts,'drafts':2},indent=2)+'\n')
print(f'Imported {len(posts)} posts; preserved two unpublished draft sources.')
