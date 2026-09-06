#!/usr/bin/env python3
"""Check generated output without third-party Python dependencies."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
import hashlib, json, re, subprocess, sys, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
SITE=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else ROOT/'_site'
# Read the same compiled Lean registry used by the generator. Run lake build first.
result=subprocess.run(['lake','env','lean','--run','scripts/site-metadata.lean'],
                      cwd=ROOT, capture_output=True, text=True)
try:
    if result.returncode: raise ValueError(result.stdout + result.stderr)
    metadata=json.loads(result.stdout)
except ValueError as exc:
    sys.exit(f'Cannot read compiled post registry. Run lake build first.\n{exc}')
posts=[p for p in metadata['posts'] if not p['draft']]
site_url=metadata['url'].rstrip('/')
page_size=metadata['postsPerPage']
page_count=max(1,(len(posts)+page_size-1)//page_size)
errors=[]
def check(test, message):
    if not test: errors.append(message)
class Page(HTMLParser):
    def __init__(self,path):
        super().__init__(convert_charrefs=True)
        self.path=path; self.base=None; self.links=[]; self.ids=set(); self.scripts=[]; self.post_links=0; self.post_targets=[]
        self.raw=path.read_text(); self.feed(self.raw)
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='base': self.base=a.get('href')
        if 'id' in a: self.ids.add(a['id'])
        if tag=='a' and a.get('class')=='post-link':
            self.post_links+=1; self.post_targets.append(a.get('href',''))
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
def html_path(route):
    return route+'index.html' if route.endswith('/') else route
for post in metadata['posts']:
    for route in {post['route'],post['publicRoute']}:
        rel=html_path(route)
        if post['draft']:
            check(rel not in pages, f"Draft page leaked: {rel}; regenerate into a clean output directory")
        else:
            check(rel in pages,f"Missing post page: {rel}")
public_urls=[site_url+'/'+p['publicRoute'] for p in posts]
check(len(set(public_urls))==len(posts),'Duplicate public post URLs in registry')
check(len({p['route'] for p in posts})==len(posts),'Duplicate generated post routes in registry')
# Check every pagination slice and its links, including one-page and empty blogs.
listing={rel:p for rel,p in pages.items() if rel=='index.html' or re.fullmatch(r'page[0-9]+/index.html',rel)}
expected_listing=['index.html']+[f'page{n}/index.html' for n in range(2,page_count+1)]
check(set(listing)==set(expected_listing),'Missing or stale pagination pages')
for n,rel in enumerate(expected_listing):
    if rel not in listing: continue
    page=listing[rel]
    base=urljoin(site_url+'/'+rel,page.base or '')
    actual=[urljoin(base,target) for target in page.post_targets]
    check(actual==public_urls[n*page_size:(n+1)*page_size],
          f'{rel}: pagination drops, repeats, or reorders posts')
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
        check(h.json[0].get('sameAs')==metadata['sameAs'],f'{rel}: social profiles differ from configuration')
        if rel in {html_path(r) for p in posts for r in (p['route'],p['publicRoute'])}:
            check(h.json[0]['@type']=='BlogPosting' and h.meta.get('article:published_time'), f'{rel}: missing article metadata')
atom={'a':'http://www.w3.org/2005/Atom'}
feed=ET.parse(SITE/'feed.xml').getroot()
check(feed.tag=='{http://www.w3.org/2005/Atom}feed','Feed is not Atom')
entries=feed.findall('a:entry',atom)
check(len(entries)==len(posts),f'Atom feed entry count differs: expected {len(posts)}, got {len(entries)}')
from datetime import datetime
for entry,post in zip(entries,posts):
    check(entry.findtext('a:title',namespaces=atom)==post['title'],'Atom title or ordering differs')
    link=entry.find('a:link',atom)
    check(link is not None and link.get('href')==site_url+'/'+post['publicRoute'],f"Atom link differs: {post['title']}")
    check(entry.findtext('a:id',namespaces=atom)==site_url+'/'+post['publicRoute'],'Atom entry ID differs')
    check([c.get('term') for c in entry.findall('a:category',atom)]==post['categories'],'Atom categories differ')
    for key in ('updated','published'):
        stamp=entry.findtext('a:'+key,namespaces=atom)
        check(stamp==post['publishedAt'],f"Atom {key} differs: {post['title']}")
        try: check(datetime.fromisoformat(stamp).tzinfo is not None,'Missing Atom timezone')
        except (ValueError,TypeError): errors.append('Invalid Atom date')
def page_url(n):
    return site_url+('/' if n==1 else f'/page{n}/')
for n,rel in enumerate(expected_listing,1):
    if rel not in pages: continue
    links=Head(pages[rel].raw).links
    for key,wanted in [('prev',page_url(n-1) if n>1 else None),
                       ('next',page_url(n+1) if n<page_count else None)]:
        check(links.get(key,{}).get('href')==wanted,f'{rel}: incorrect pagination {key} metadata')
sitemap_urls={e.text for e in ET.parse(SITE/'sitemap.xml').getroot().findall(
    '{http://www.sitemaps.org/schemas/sitemap/0.9}url/{http://www.sitemaps.org/schemas/sitemap/0.9}loc')}
check(set(public_urls)<=sitemap_urls,'Sitemap omits published posts')
for post in metadata['posts']:
    if post['draft']:
        check(site_url+'/'+post['publicRoute'] not in sitemap_urls,'Draft URL leaked into sitemap')
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
print(f'PASS: {len(pages)} HTML pages; local links and anchors at root and project subpath; {len(posts)} published posts; pagination; media hashes; draft exclusion; page-local three.js; SEO, JSON-LD, Atom feed and sitemap.')
print('Original source checksum verification passed.' if source.exists() else 'Original unavailable; source check skipped (expected in CI).')
