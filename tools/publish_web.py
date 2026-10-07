from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Builds' / 'Web'
DESTINATION = ROOT / 'docs'
REQUIRED = ('index.html', 'index.js', 'index.wasm', 'index.pck')
for name in REQUIRED:
    if not (SOURCE / name).is_file():
        raise SystemExit(f'Missing Web export: {SOURCE / name}')
if '<title>Just go up!!</title>' not in (SOURCE / 'index.html').read_text(encoding='utf-8'):
    raise SystemExit('Web export is not the current Just go up!! game')
DESTINATION.mkdir(exist_ok=True)
manifest = {}
for source in SOURCE.iterdir():
    if source.suffix not in {'.html', '.js', '.wasm', '.pck', '.png', '.txt'}:
        continue
    target = DESTINATION / source.name
    shutil.copy2(source, target)
    manifest[source.name] = {'bytes': target.stat().st_size,
                             'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
(DESTINATION / '.nojekyll').touch()
(DESTINATION / '.gdignore').touch()
(DESTINATION / 'build-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
print('Published latest Web export to docs; verified', len(manifest), 'files.')
