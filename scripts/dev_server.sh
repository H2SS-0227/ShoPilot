#!/usr/bin/env bash
set -euo pipefail
python3 -m uvicorn app.main:app --reload --app-dir server --host 0.0.0.0 --port 8000
