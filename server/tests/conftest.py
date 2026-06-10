import sys
import os
from pathlib import Path

os.environ.setdefault("ENABLE_LLM", "false")

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "server"))
