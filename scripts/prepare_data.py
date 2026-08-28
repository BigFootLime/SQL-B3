"""Vérifie et extrait les CSV publics nécessaires au projet, sans réseau."""
import hashlib
import json
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'datasets/manifest.json').read_text(encoding='utf-8'))
archive = root / 'datasets/coffee-csv.zip'
if hashlib.sha256(archive.read_bytes()).hexdigest() != manifest['zip_sha256']:
    raise SystemExit('Archive Coffee corrompue : empreinte SHA-256 différente.')
dest = root / 'data/stackexchange-coffee/csv'
dest.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(archive) as z:
    if set(z.namelist()) != set(manifest['files']):
        raise SystemExit('Contenu inattendu dans l’archive.')
    for name, info in manifest['files'].items():
        if Path(name).name != name:
            raise SystemExit('Nom de fichier invalide dans le manifeste.')
        data = z.read(name)
        if hashlib.sha256(data).hexdigest() != info['sha256']:
            raise SystemExit(f'Empreinte incorrecte : {name}')
        (dest / name).write_bytes(data)
        print(f"{name} : {info['rows']} lignes vérifiées")
