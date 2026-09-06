#!/usr/bin/env python3
"""Check generated output without third-party Python dependencies."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
import hashlib, json, sys, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
SITE=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else ROOT/'_site'
errors=[]
def check(test, message):
    if not test: errors.append(message)
class Page(HTMLParser):
    def __init__(self,path):
        super().__init__(convert_charrefs=True)
        self.path=path; self.base=None; self.links=[]; self.ids=set(); self.scripts=[]; self.post_links=0
        self.raw=path.read_text(); self.feed(self.raw)
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='base': self.base=a.get('href')
        if 'id' in a: self.ids.add(a['id'])
        if tag=='a' and a.get('class')=='post-link': self.post_links+=1
        if tag=='script': self.scripts.append(a.get('src',''))
        for key in ('href','src','poster'):
            if key in a and tag!='base': self.links.append((tag,a[key]))
pages={p.relative_to(SITE).as_posix():Page(p) for p in SITE.rglob('*.html')}
check(bool(pages),'No generated HTML')
# Validate under a repository subpath too, to catch accidentally root-relative URLs.
for prefix in ('/', '/repository/'):
    origin='https://local.test'+prefix
    for rel,p in pages.items():
        url=origin+rel
        base=urljoin(url,p.base or '')
        check('{%' not in p.raw and '{{site.' not in p.raw, f'{rel}: unconverted Liquid')
        for tag,target in p.links:
            resolved=urlsplit(urljoin(base,target))
            if resolved.netloc!='local.test' or resolved.scheme not in ('https','http'): continue
            check(resolved.path.startswith(prefix),f'{rel}: URL escapes project prefix: {target}')
            if not resolved.path.startswith(prefix): continue
            local=unquote(resolved.path[len(prefix):])
            path=SITE/local
            if path.is_dir(): local=local.rstrip('/')+'/index.html' if local else 'index.html'; path=SITE/local
            check(path.is_file(),f'{rel}: missing local target {target} -> {local}')
            if resolved.fragment and local in pages:
                check(unquote(resolved.fragment) in pages[local].ids, f'{rel}: missing anchor {target}')
        if rel!='examples/index.html':
            check('three@' not in p.raw and 'scenes/torus' not in p.raw and 'import(' not in p.raw,
                  f'{rel}: three.js inclusion leaked')
check('scenes/torus.js' in pages.get('examples/index.html',type('Empty',(),{'raw':''})()).raw,
      'Examples page does not include the scene')
inv=json.loads((ROOT/'scripts/migration-inventory.json').read_text())
for post in inv['posts']:
    check(post['old'] in pages, f"Missing legacy route {post['old']}")
    check(post['route']+'index.html' in pages,f"Missing Verso route {post['route']}")
check(not any('template' in rel or 'another' in rel for rel in pages),'Unpublished drafts leaked')
# Configurable page size is read from the generated pagination, rather than assumed.
listing=[p for rel,p in pages.items() if rel=='index.html' or (rel.startswith('page') and rel.endswith('/index.html'))]
check(sum(p.post_links for p in listing)==len(inv['posts']),'Pagination drops or repeats published posts')
for name in ('feed.xml','sitemap.xml'):
    try: ET.parse(SITE/name)
    except Exception as e: errors.append(f'{name}: {e}')
check((SITE/'.nojekyll').exists(),'Missing .nojekyll')
# Verify SEO against the source homepage and post metadata, excluding the generator name.
class Head(HTMLParser):
    def __init__(self, raw):
        super().__init__(); self.meta={}; self.links={}; self.json=[]; self.capture=False; self.buffer=''; self.feed(raw)
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='meta': self.meta[a.get('name',a.get('property',''))]=a.get('content','')
        if tag=='link': self.links[a.get('rel','')]=a
        if tag=='script' and a.get('type')=='application/ld+json': self.capture=True; self.buffer=''
    def handle_data(self,data):
        if self.capture: self.buffer+=data
    def handle_endtag(self,tag):
        if tag=='script' and self.capture:
            self.capture=False
            try: self.json.append(json.loads(self.buffer))
            except ValueError: errors.append('Invalid JSON-LD')
for rel,page in pages.items():
    if rel=='google6d9c71355863f158.html': continue
    h=Head(page.raw)
    for key in ('author','description','og:title','og:locale','og:description','og:site_name','og:image',
                'og:type','og:url','twitter:card','twitter:image','twitter:title','google-site-verification',
                'msapplication-TileColor','theme-color'):
        check(bool(h.meta.get(key)),f'{rel}: missing SEO field {key}')
    check(len(h.json)==1,f'{rel}: expected one JSON-LD object')
    check(h.links.get('alternate',{}).get('type')=='application/atom+xml',f'{rel}: incorrect feed discovery type')
    if h.json:
        check(h.json[0]['url']==h.links['canonical']['href'],f'{rel}: inconsistent JSON-LD canonical')
        check(len(h.json[0]['sameAs'])==5,f'{rel}: lost original social profiles')
        if rel.startswith('arts/20'):
            check(h.json[0]['@type']=='BlogPosting' and h.meta.get('article:published_time'), f'{rel}: missing article metadata')
atom={'a':'http://www.w3.org/2005/Atom'}
feed=ET.parse(SITE/'feed.xml').getroot()
check(feed.tag=='{http://www.w3.org/2005/Atom}feed','Feed is not Atom')
entries=feed.findall('a:entry',atom)
check(len(entries)==len(inv['posts']),'Atom feed entry count differs')
from datetime import datetime
for entry,post in zip(entries,inv['posts']):
    check(entry.findtext('a:title',namespaces=atom)==post['title'],'Atom title or ordering differs')
    check(entry.find('a:link',atom).get('href').endswith(post['old']),'Atom link differs')
    for key in ('updated','published'):
        stamp=entry.findtext('a:'+key,namespaces=atom)
        try: check(datetime.fromisoformat(stamp).tzinfo is not None,'Missing Atom timezone')
        except (ValueError,TypeError): errors.append('Invalid Atom date')
check(Head(pages['index.html'].raw).links.get('next',{}).get('href','').endswith('/page2/'),'Missing pagination next metadata')
check(Head(pages['page2/index.html'].raw).links.get('prev',{}).get('href','').endswith('/'),'Missing pagination previous metadata')
source=Path(inv['source'])
manifest=json.loads((ROOT/'scripts/source-checksums.json').read_text())
for rel,digest in manifest.items():
    if rel.startswith('assets/') and not rel.endswith(('.scss','.DS_Store')):
        dest=SITE/rel
        check(dest.is_file() and hashlib.sha256(dest.read_bytes()).hexdigest()==digest, f'Asset differs: {rel}')
if source.exists():
    for rel,digest in manifest.items():
        p=source/rel
        check(p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==digest,f'Original source changed: {rel}')
if errors:
    print('\n'.join(sorted(set(errors)))); sys.exit(1)
print(f'PASS: {len(pages)} HTML pages; local links and anchors at root and project subpath; six posts; pagination; media hashes; draft exclusion; page-local three.js; SEO, JSON-LD, Atom feed and sitemap.')
print('Original source checksum verification passed.' if source.exists() else 'Original unavailable; source check skipped (expected in CI).')
