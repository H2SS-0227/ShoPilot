from pathlib import Path
import json


def iter_raw_product_files(dataset_root: str) -> list[Path]:
    root = Path(dataset_root).resolve()
    return sorted(root.glob("*/data/*.json"))


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
