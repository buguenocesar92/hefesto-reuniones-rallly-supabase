import hashlib,json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PRODUCT='hefesto-reuniones'
VERSION='4.15.4'
FILES=['.env','compose.yaml','compose.bootstrap.yaml','ops/start.sh','ops/validate.cjs','ops/preflight.sh','ops/preflight.sql','ops/production.sql','certs/ca.crt']
def dc(*args,**kw):
    return subprocess.run(['docker','compose','--project-directory',str(ROOT),'-f',str(ROOT/'compose.yaml'),*args],check=True,**kw)
def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def verify(path):
    src=Path(path).resolve();m=json.loads((src/'manifest.json').read_text())
    if (m.get('product'),m.get('version'),m.get('status'))!=(PRODUCT,VERSION,'completed'):raise SystemExit('Manifest incorrecto')
    if set(m.get('sha256',{}))!=set(FILES+['public.dump']):raise SystemExit('Lista de archivos inesperada')
    for name,digest in m['sha256'].items():
        p=src/name
        if p.is_symlink() or not p.is_file() or src not in p.resolve().parents:raise SystemExit('Ruta no admitida')
        if sha(p)!=digest:raise SystemExit('Checksum incorrecto: '+name)
    return src
