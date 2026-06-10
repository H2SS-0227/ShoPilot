from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "server"

if str(SERVER) not in sys.path:
    sys.path.insert(0, str(SERVER))

from app.main import app  # noqa: E402,F401
