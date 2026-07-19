#!/usr/bin/env bash
set -euo pipefail

exec /home/chaconne/.gbrain/bin/gbrain_with_google_env.sh serve --http --port 3131 --bind 127.0.0.1 --suppress-bootstrap-token
