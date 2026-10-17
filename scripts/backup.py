#!/usr/bin/env python3
import datetime,json,os,shutil
from common import ROOT,FILES,PRODUCT,VERSION,dc,sha
os.umask(0o077)
for name in FILES:
    if not (ROOT/name).is_file():raise SystemExit('Falta archivo '+name)
p=ROOT/'backups'/datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ');p.mkdir(parents=True,mode=0o700)
running=bool(dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip())
try:
    dc('stop','app')
    with (p/'public.dump').open('wb') as f:
        dc('run','--rm','--no-deps','-T','--entrypoint','pg_dump','dbtools','--format=custom','--schema=public','--no-owner','--no-acl',stdout=f)
    for name in FILES:
        target=p/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/name,target)
    m={'product':PRODUCT,'version':VERSION,'status':'completed','sha256':{n:sha(p/n) for n in FILES+['public.dump']}}
    (p/'manifest.json').write_text(json.dumps(m,indent=2))
    print('Respaldo:',p,'Contiene credenciales, datos y sesiones. Restaurar puede recuperar correos pendientes.')
finally:
    if running:dc('start','app')
