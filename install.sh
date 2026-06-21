#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
home_dir="${HOME:?HOME is required}"
codex_home="${CODEX_HOME:-$home_dir/.codex}"
gbrain_home="${GBRAIN_HOME:-$home_dir/.gbrain}"

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp -a "$path" "$path.backup-$stamp"
  fi
}

install_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  cp -a "$src" "$dst"
}

install_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  rm -rf "$dst"
  cp -a "$src" "$dst"
}

mkdir -p "$codex_home/skills" "$gbrain_home/bin" "$gbrain_home/logs" "$home_dir/.config/systemd/user"

install_file "$repo_dir/codex/AGENTS.md" "$codex_home/AGENTS.md"

for skill_dir in "$repo_dir"/codex/skills/*; do
  [ -d "$skill_dir" ] || continue
  install_dir "$skill_dir" "$codex_home/skills/$(basename "$skill_dir")"
done

install_file "$repo_dir/gbrain/bin/gbrain_with_google_env.sh" "$gbrain_home/bin/gbrain_with_google_env.sh"
install_file "$repo_dir/gbrain/bin/gbrain_http_with_google_env.sh" "$gbrain_home/bin/gbrain_http_with_google_env.sh"
install_file "$repo_dir/gbrain/bin/memory_distill.py" "$gbrain_home/bin/memory_distill.py"
chmod 700 "$gbrain_home/bin/gbrain_with_google_env.sh" "$gbrain_home/bin/gbrain_http_with_google_env.sh" "$gbrain_home/bin/memory_distill.py"

install_file "$repo_dir/gbrain/systemd/gbrain-http.service" "$home_dir/.config/systemd/user/gbrain-http.service"
install_file "$repo_dir/gbrain/systemd/gbrain-memory-distill.service" "$home_dir/.config/systemd/user/gbrain-memory-distill.service"
install_file "$repo_dir/gbrain/systemd/gbrain-memory-distill.timer" "$home_dir/.config/systemd/user/gbrain-memory-distill.timer"

python3 "$repo_dir/scripts/check-skill-deps.py"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  systemctl --user enable --now gbrain-http.service || true
  systemctl --user enable --now gbrain-memory-distill.timer || true
fi

echo "kmh-agent-kit installed."
echo "Next: read docs/onboarding-new-server.md and run ~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast."
