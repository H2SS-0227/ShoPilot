from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))

from app.core.config import settings
from app.data.loader import iter_raw_product_files, load_json
from app.data.normalizer import normalize_product


def main() -> None:
    dataset_root = (ROOT / settings.dataset_root).resolve()
    products = [
        normalize_product(load_json(path), dataset_root=str(dataset_root)).model_dump()
        for path in iter_raw_product_files(str(dataset_root))
    ]
    output = ROOT / settings.normalized_products_path
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(products, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(products)} products to {output}")


if __name__ == "__main__":
    main()
