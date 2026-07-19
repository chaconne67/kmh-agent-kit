#!/usr/bin/env bash
set -euo pipefail

gemini_key="$(
  grep -m1 '^GEMINI_API_KEY=' /home/chaconne/exdigm/.env | cut -d= -f2-
)"
gemini_key="${gemini_key%\"}"
gemini_key="${gemini_key#\"}"
gemini_key="${gemini_key%\'}"
gemini_key="${gemini_key#\'}"

export GOOGLE_GENERATIVE_AI_API_KEY="$gemini_key"
export PATH="/home/chaconne/.bun/bin:$PATH"
unset DATABASE_URL OPENAI_API_KEY OPENROUTER_API_KEY

cd /home/chaconne
exec /home/chaconne/.bun/bin/gbrain "$@"
