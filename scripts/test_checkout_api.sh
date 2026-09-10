#!/usr/bin/env bash
set -euo pipefail
python -m pip install -q -r apps/checkout-api/requirements.txt
python -m unittest apps.checkout-api.test_app 2>/dev/null || python -m unittest discover -s apps/checkout-api -p 'test_*.py'
