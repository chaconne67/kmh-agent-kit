#!/usr/bin/env bash
set -euo pipefail

# kmh-agent-kit installer — 심링크 연결기.
# 일상 동기화는 git commit/push/pull만으로 끝난다. 이 스크립트는
# 새 서버 최초 연결, 새 스킬 추가 후 링크 반영, 프로젝트 프로필 연결에만 쓴다.
#
# usage:
#   ./install.sh                              # 전역 설치 (claude + codex + gbrain)
#   ./install.sh --project <경로> <프로필명>   # 프로젝트 프로필 연결 (예: --project ~/exdigm exdigm)

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
home_dir="${HOME:?HOME is required}"
claude_home="${CLAUDE_HOME:-$home_dir/.claude}"
codex_home="${CODEX_HOME:-$home_dir/.codex}"
gbrain_home="${GBRAIN_HOME:-$home_dir/.gbrain}"
stamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$home_dir/.kmh-agent-kit-backup-$stamp"

# 링크가 아닌 기존 항목은 백업 폴더로 옮긴 뒤 심링크를 건다. 이미 올바른 링크면 그대로 둔다.
link_entry() {
  local target="$1" link="$2"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$target" ] && return 0
    rm "$link"
  elif [ -e "$link" ]; then
    mkdir -p "$backup_root"
    local flat="${link#"$home_dir"/}"
    flat="${flat//\//_}"
    mv "$link" "$backup_root/$flat"
  fi
  mkdir -p "$(dirname "$link")"
  ln -s "$target" "$link"
}

# 프로필 디렉토리의 모든 항목을 live 디렉토리에 링크하고,
# 프로필에서 사라진 스킬을 가리키는 깨진 링크는 정리한다(스킬 삭제의 pull 전파).
link_profile() {
  local profile="$1" live="$2"
  mkdir -p "$live"
  local entry live_entry
  for entry in "$profile"/*; do
    [ -e "$entry" ] || continue
    link_entry "$entry" "$live/$(basename "$entry")"
  done
  for live_entry in "$live"/*; do
    [ -L "$live_entry" ] || continue
    case "$(readlink "$live_entry")" in
      "$profile"/*) [ -e "$live_entry" ] || rm "$live_entry" ;;
    esac
  done
}

if [ "${1:-}" = "--gbrain" ]; then
  agent_name="${2:?usage: install.sh --gbrain <에이전트>}"
  card="$repo_dir/gbrain-cards/$agent_name.md"
  [ -f "$card" ] || { echo "[error] 카드 없음: $card" >&2; exit 1; }
  link_entry "$card" "$home_dir/.gbrain-agent.md"
  echo "gbrain card '$agent_name' → ~/.gbrain-agent.md"
  [ -d "$backup_root" ] && echo "기존 파일 백업: $backup_root"
  exit 0
fi

if [ "${1:-}" = "--project" ]; then
  proj_path="${2:?usage: install.sh --project <경로> <프로필명>}"
  proj_name="${3:?usage: install.sh --project <경로> <프로필명>}"
  profile="$repo_dir/projects/$proj_name"
  [ -d "$profile" ] || { echo "[error] 프로젝트 프로필 없음: $profile" >&2; exit 1; }
  [ -d "$proj_path" ] || { echo "[error] 프로젝트 경로 없음: $proj_path" >&2; exit 1; }
  [ -d "$profile/skills" ] && link_profile "$profile/skills" "$proj_path/.claude/skills"
  [ -d "$profile/skills" ] && link_profile "$profile/skills" "$proj_path/.codex/skills"
  [ -f "$profile/CLAUDE.md" ] && link_entry "$profile/CLAUDE.md" "$proj_path/CLAUDE.md"
  [ -f "$profile/AGENTS.md" ] && link_entry "$profile/AGENTS.md" "$proj_path/AGENTS.md"
  echo "project '$proj_name' linked into $proj_path"
  [ -d "$backup_root" ] && echo "기존 파일 백업: $backup_root"
  exit 0
fi

# ── 전역 설치: 스킬 프로필 + 전역 지침 (심링크) ─────────────────────────
link_profile "$repo_dir/claude/skills" "$claude_home/skills"
link_profile "$repo_dir/codex/skills" "$codex_home/skills"
link_entry "$repo_dir/claude/CLAUDE.md" "$claude_home/CLAUDE.md"
link_entry "$repo_dir/codex/AGENTS.md" "$codex_home/AGENTS.md"

# ── GBrain 런타임 자산 (복사식 유지 — 실행 파일은 링크하지 않는다) ──────
backup_if_exists() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    cp -a "$path" "$path.backup-$stamp"
  fi
}

install_file() {
  local src="$1" dst="$2"
  cmp -s "$src" "$dst" 2>/dev/null && return 0
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  cp -a "$src" "$dst"
}

mkdir -p "$gbrain_home/bin" "$gbrain_home/logs" "$home_dir/.config/systemd/user"
install_file "$repo_dir/gbrain/bin/gbrain_with_google_env.sh" "$gbrain_home/bin/gbrain_with_google_env.sh"
install_file "$repo_dir/gbrain/bin/gbrain_http_with_google_env.sh" "$gbrain_home/bin/gbrain_http_with_google_env.sh"
install_file "$repo_dir/gbrain/bin/memory_distill.py" "$gbrain_home/bin/memory_distill.py"
install_file "$repo_dir/gbrain/bin/gbrain-agent" "$gbrain_home/bin/gbrain-agent"
chmod 700 "$gbrain_home/bin/gbrain_with_google_env.sh" "$gbrain_home/bin/gbrain_http_with_google_env.sh" "$gbrain_home/bin/memory_distill.py"
chmod 755 "$gbrain_home/bin/gbrain-agent"

# GBrain 본체 서버(정책 파일 존재)에서만: 정책에 등록된 공간 에이전트마다 이름 심링크 생성
policy_file="$home_dir/.gbrain/memory/agent-policy.toml"
if [ -f "$policy_file" ]; then
  mkdir -p "$home_dir/.local/bin"
  link_entry "$gbrain_home/bin/gbrain-agent" "$home_dir/.local/bin/gbrain-agent"
  for agent_name in $(sed -n 's/^\[agents\.\([A-Za-z0-9_-]*\)\]/\1/p' "$policy_file"); do
    if sed -n "/^\[agents\.$agent_name\]/,/^\[/p" "$policy_file" | grep -q '^private_source'; then
      link_entry "$gbrain_home/bin/gbrain-agent" "$home_dir/.local/bin/gbrain-$agent_name"
    fi
  done
fi

install_file "$repo_dir/gbrain/systemd/gbrain-http.service" "$home_dir/.config/systemd/user/gbrain-http.service"
install_file "$repo_dir/gbrain/systemd/gbrain-memory-distill.service" "$home_dir/.config/systemd/user/gbrain-memory-distill.service"
install_file "$repo_dir/gbrain/systemd/gbrain-memory-distill.timer" "$home_dir/.config/systemd/user/gbrain-memory-distill.timer"

python3 "$repo_dir/scripts/check-skill-deps.py"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  systemctl --user enable --now gbrain-http.service || true
  systemctl --user enable --now gbrain-memory-distill.timer || true
fi

echo "kmh-agent-kit installed (symlink mode)."
[ -d "$backup_root" ] && echo "기존 파일 백업: $backup_root"
echo "Next: docs/onboarding-new-server.md 참조. GBrain 확인: ~/.gbrain/bin/gbrain_with_google_env.sh doctor --fast"
