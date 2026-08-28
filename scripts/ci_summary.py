"""Publie un bilan dans le job, sans utiliser le quota de stockage des artifacts."""
import json
import os
from pathlib import Path

root = Path(__file__).resolve().parents[1]
lines = ['# Vérification PostgreSQL', '']
for name in ['benchmark', 'optimisation']:
    path = root / 'rapports' / (name + '.json')
    if path.exists():
        data = json.loads(path.read_text(encoding='utf-8'))
        data.pop('plans', None)
        data.pop('tables_et_index', None)
        data.pop('pg_stat_statements', None)
        lines.extend([f'## {name}', '```json', json.dumps(data, ensure_ascii=False, indent=2), '```'])
for p in sorted((root / 'rapports/logs').glob('*.log')):
    checks = [line for line in p.read_text(encoding='utf-8', errors='replace').splitlines()
              if 'NOTICE:' in line and 'OK :' in line]
    if checks:
        lines.extend([f'## {p.stem}', '```text', *checks, '```'])
text = '\n'.join(lines) + '\n'
print(text)
if os.environ.get('GITHUB_STEP_SUMMARY'):
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as stream:
        stream.write(text)
