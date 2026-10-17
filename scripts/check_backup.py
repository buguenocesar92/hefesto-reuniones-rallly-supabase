#!/usr/bin/env python3
import sys
from common import verify
if len(sys.argv)!=2:raise SystemExit('Uso: python3 scripts/check_backup.py /ruta/respaldo')
verify(sys.argv[1]);print('Manifest y checksums correctos. Esto no demuestra recuperacion PostgreSQL ni autenticidad del respaldo.')
