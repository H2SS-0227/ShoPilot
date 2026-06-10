# -*- coding: utf-8 -*-
from pathlib import Path
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / '.stitch' / 'screens.json'
METADATA_DIR = ROOT / '.stitch' / 'screen-metadata'
ENV_FILE = ROOT / '.stitch' / '.env'
SCREENSHOT_DIR = ROOT / 'client' / 'assets' / 'stitch' / 'screenshots'
HTML_DIR = ROOT / 'client' / 'assets' / 'stitch' / 'html'
FIGMA_DIR = ROOT / 'client' / 'assets' / 'stitch' / 'figma'

for directory in (SCREENSHOT_DIR, HTML_DIR, FIGMA_DIR):
    directory.mkdir(parents=True, exist_ok=True)


def load_local_env() -> None:
    if not ENV_FILE.exists():
        return
    for line in ENV_FILE.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        os.environ.setdefault(key.strip(), value.strip())


def download(url: str, output: Path) -> None:
    if not url:
        return
    command = ['curl', '-L', url, '-o', str(output)]
    stitch_api_key = os.getenv('STITCH_API_KEY')
    if stitch_api_key:
        command = ['curl', '-L', '-H', f'x-goog-api-key: {stitch_api_key}', url, '-o', str(output)]
    subprocess.run(command, check=True)


def main() -> None:
    load_local_env()
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    missing = []
    downloaded = []
    for screen in manifest['screens']:
        slug = screen['slug']
        metadata_path = METADATA_DIR / f'{slug}.json'
        if not metadata_path.exists():
            missing.append(slug)
            continue
        metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
        screenshot_url = metadata.get('screenshot', {}).get('downloadUrl')
        html_url = metadata.get('htmlCode', {}).get('downloadUrl')
        figma_url = metadata.get('figmaExport', {}).get('downloadUrl')
        if screenshot_url:
            download(screenshot_url, SCREENSHOT_DIR / f'{slug}.png')
        if html_url:
            download(html_url, HTML_DIR / f'{slug}.html')
        if figma_url:
            download(figma_url, FIGMA_DIR / f'{slug}.figma')
        downloaded.append(slug)
    print('Downloaded:', ', '.join(downloaded) if downloaded else 'none')
    if missing:
        print('Missing metadata:', ', '.join(missing))
        print('请先通过 Stitch MCP get_screen 保存 .stitch/screen-metadata/{slug}.json')


if __name__ == '__main__':
    main()
