"""Utilidades compartidas del kit de reuniones.

La validacion del respaldo tiene UNA sola fuente de verdad:
scripts/check_backup.py (docs/CONTRATO-RESPALDO.md). Este modulo mantiene su
API publica (ROOT, PRODUCT, VERSION, FILES, dc, sha, verify) y delega la
verificacion para que no exista una segunda interpretacion del contrato.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = json.loads((ROOT / 'scripts' / 'kit.json').read_text())
PRODUCT = KIT['software']
VERSION = KIT['version']
FILES = KIT.get('piezas', [])


def dc(*args, **kw):
    return subprocess.run(['docker', 'compose', '--project-directory', str(ROOT),
                           '-f', str(ROOT / 'compose.yaml'), *args], check=True, **kw)


def sha(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def verify(path):
    """Valida el respaldo con el verificador canonico del contrato."""
    verificador = ROOT / 'scripts' / 'check_backup.py'
    proc = subprocess.run([sys.executable, str(verificador), str(path),
                           '--software', PRODUCT], capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit((proc.stderr or proc.stdout).strip() or 'Respaldo invalido')
    return Path(path).resolve()
