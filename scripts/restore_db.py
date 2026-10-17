#!/usr/bin/env python3
import os,re,subprocess,sys,tempfile
from pathlib import Path
from common import ROOT,verify,dc
if len(sys.argv)!=3 or sys.argv[2]!='--accept-restored-mail':
    raise SystemExit('Uso: python3 scripts/restore_db.py /ruta/respaldo --accept-restored-mail (puede recuperar sesiones y correos pendientes)')
backup=verify(sys.argv[1]);dump=backup/'public.dump'
def secret(path):
    for line in path.read_text().splitlines():
        if line.startswith('SECRET_PASSWORD='):return line.split('=',1)[1].strip().strip("\"'")
if not secret(ROOT/'.env') or secret(ROOT/'.env')!=secret(backup/'.env'):raise SystemExit('Conservar SECRET_PASSWORD original')
if dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip():raise SystemExit('Detener app en destino antes de restaurar')
dc('run','--rm','--no-deps','-T','-e','BOOTSTRAP_MODE=true','preflight')
count=dc('run','--rm','--no-deps','-T','--entrypoint','psql','dbtools','--no-psqlrc','-Atc',"SELECT count(*) FROM pg_tables WHERE schemaname='public'",capture_output=True,text=True).stdout.strip()
if count!='0':raise SystemExit('public no esta vacio; no se sobrescriben datos')
with dump.open('rb') as stream:
    toc=dc('run','--rm','--no-deps','-T','--entrypoint','pg_restore','dbtools','--list',stdin=stream,stdout=subprocess.PIPE).stdout.decode()
lines=[line for line in toc.splitlines() if not re.match(r'^\d+;\s+\d+\s+\d+\s+SCHEMA\s+-\s+public(?:\s|$)',line)]
# Citext ya se prepara con el administrador en destino; no recrear ni comentar su extension.
lines=[line for line in lines if not re.search(r'\sEXTENSION\s+-\s+citext(?:\s|$)|\sCOMMENT\s+-\s+EXTENSION\s+citext(?:\s|$)',line)]
with tempfile.TemporaryDirectory(prefix='hefesto-reuniones-restore-') as d:
    path=Path(d)/'restore.list';path.write_text('\n'.join(lines)+'\n');os.chmod(d,0o755);os.chmod(path,0o644)
    with dump.open('rb') as stream:
        dc('run','--rm','--no-deps','-T','-v',d+':/restore:ro','--entrypoint','pg_restore','dbtools','--exit-on-error','--single-transaction','--no-owner','--no-acl','--use-list=/restore/restore.list','--dbname=postgres',stdin=stream)
print('BD restaurada en proyecto nuevo. Probar solo por tunel privado y con votaciones ficticias.')
