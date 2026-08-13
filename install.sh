#!/usr/bin/env bash
set -euo pipefail

# kmh-agent-kit installer — 전역 자산, GBrain 카드, 프로젝트 프로필을 한 경로로 연결한다.
# 공식 설치 경로: ./install.sh <에이전트>
# 신규 공간 생성: ./install.sh --new <에이전트>

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
home_dir="${HOME:?HOME is required}"
claude_home="${CLAUDE_HOME:-$home_dir/.claude}"
codex_home="${CODEX_HOME:-$home_dir/.codex}"
gbrain_home="${GBRAIN_HOME:-$home_dir/.gbrain}"
policy_file="${GBRAIN_POLICY_FILE:-$gbrain_home/memory/agent-policy.toml}"
gbrain_cli="${GBRAIN_CLI_WRAPPER:-$gbrain_home/bin/gbrain_with_google_env.sh}"
gbrain_host="${GBRAIN_HOST:-chaconne@49.247.45.243}"
stamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$home_dir/.kmh-agent-kit-backup-$stamp"

die() {
  echo "[error] $*" >&2
  exit 64
}

show_usage() {
  cat <<'EOF'
KMH Agent Kit

새로운 프로젝트 역할을 처음 등록:
  ./install.sh --new abc-project
  ./install.sh --new abc-project --dry-run

이미 등록된 역할을 설치 — 해당 등록 이름 하나만 사용:
  ./install.sh main
  ./install.sh fundkeeper
  ./install.sh rndlog
  ./install.sh ceoloan
  ./install.sh judy

그 외:
  ./install.sh                         공용 스킬·전역 지침만 설치
  ./install.sh --project ~/exdigm exdigm
  ./install.sh --help
EOF
}

validate_agent_name() {
  local agent_name="$1"
  [[ "$agent_name" =~ ^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$ ]] ||
    die "에이전트 이름은 영문 소문자·숫자·중간 하이픈으로 된 1~32자여야 합니다: $agent_name"
}

# 링크가 아닌 기존 항목은 백업한 뒤 연결한다. 이미 올바른 링크면 그대로 둔다.
link_entry() {
  local target="$1" link="$2"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$target" ] && return 0
    unlink "$link"
  elif [ -e "$link" ]; then
    mkdir -p "$backup_root"
    local flat="${link#"$home_dir"/}"
    flat="${flat//\//_}"
    mv "$link" "$backup_root/$flat"
  fi
  mkdir -p "$(dirname "$link")"
  ln -s "$target" "$link"
}

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
      "$profile"/*) [ -e "$live_entry" ] || unlink "$live_entry" ;;
    esac
  done
}

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

install_global() {
  link_profile "$repo_dir/claude/skills" "$claude_home/skills"
  link_profile "$repo_dir/codex/skills" "$codex_home/skills"
  link_entry "$repo_dir/claude/CLAUDE.md" "$claude_home/CLAUDE.md"
  link_entry "$repo_dir/codex/AGENTS.md" "$codex_home/AGENTS.md"

  mkdir -p "$gbrain_home/bin" "$gbrain_home/logs" "$home_dir/.config/systemd/user"
  install_file "$repo_dir/gbrain/bin/gbrain_with_google_env.sh" "$gbrain_home/bin/gbrain_with_google_env.sh"
  install_file "$repo_dir/gbrain/bin/gbrain_http_with_google_env.sh" "$gbrain_home/bin/gbrain_http_with_google_env.sh"
  install_file "$repo_dir/gbrain/bin/memory_distill.py" "$gbrain_home/bin/memory_distill.py"
  install_file "$repo_dir/gbrain/bin/gbrain-agent" "$gbrain_home/bin/gbrain-agent"
  chmod 700 "$gbrain_home/bin/gbrain_with_google_env.sh" "$gbrain_home/bin/gbrain_http_with_google_env.sh" "$gbrain_home/bin/memory_distill.py"
  chmod 755 "$gbrain_home/bin/gbrain-agent"

  if [ -f "$policy_file" ]; then
    mkdir -p "$home_dir/.local/bin"
    link_entry "$gbrain_home/bin/gbrain-agent" "$home_dir/.local/bin/gbrain-agent"
    local registered_agent
    while IFS= read -r registered_agent; do
      if sed -n "/^\[agents\.$registered_agent\]$/,/^\[/p" "$policy_file" | grep -q '^private_source'; then
        link_entry "$gbrain_home/bin/gbrain-agent" "$home_dir/.local/bin/gbrain-$registered_agent"
      fi
    done < <(sed -n 's/^\[agents\.\([A-Za-z0-9_-]*\)\]$/\1/p' "$policy_file")
  fi

  install_file "$repo_dir/gbrain/systemd/gbrain-http.service" "$home_dir/.config/systemd/user/gbrain-http.service"
  install_file "$repo_dir/gbrain/systemd/gbrain-memory-distill.service" "$home_dir/.config/systemd/user/gbrain-memory-distill.service"
  install_file "$repo_dir/gbrain/systemd/gbrain-memory-distill.timer" "$home_dir/.config/systemd/user/gbrain-memory-distill.timer"

  if [ -f "$repo_dir/shell/kit-aliases.sh" ] && ! grep -q "kmh-agent-kit/shell/kit-aliases.sh" "$home_dir/.bashrc" 2>/dev/null; then
    printf '\n# kmh-agent-kit aliases\n[ -f "%s/shell/kit-aliases.sh" ] && . "%s/shell/kit-aliases.sh"\n' "$repo_dir" "$repo_dir" >> "$home_dir/.bashrc"
    echo "~/.bashrc에 kit-aliases source 라인 추가"
  fi

  python3 "$repo_dir/scripts/check-skill-deps.py"

  if command -v systemctl >/dev/null 2>&1 && [ -x "${GBRAIN_CLI:-$home_dir/.bun/bin/gbrain}" ]; then
    systemctl --user daemon-reload || true
    systemctl --user enable --now gbrain-http.service || true
    systemctl --user enable --now gbrain-memory-distill.timer || true
  fi
}

install_project_profile() {
  local project_path="$1" profile_name="$2"
  local profile="$repo_dir/projects/$profile_name"
  [ -d "$profile" ] || die "프로젝트 프로필이 없습니다: $profile"
  [ -d "$project_path" ] || die "프로젝트 폴더가 없습니다: $project_path"
  [ -d "$profile/skills" ] && link_profile "$profile/skills" "$project_path/.claude/skills"
  [ -d "$profile/skills" ] && link_profile "$profile/skills" "$project_path/.codex/skills"
  [ -f "$profile/CLAUDE.md" ] && link_entry "$profile/CLAUDE.md" "$project_path/CLAUDE.md"
  [ -f "$profile/AGENTS.md" ] && link_entry "$profile/AGENTS.md" "$project_path/AGENTS.md"
  echo "프로젝트 프로필 연결: $profile_name → $project_path"
}

install_gbrain_card() {
  local agent_name="$1"
  local card="$repo_dir/gbrain-cards/$agent_name.md"
  [ -f "$card" ] || die "GBrain 카드가 없습니다. 신규라면 실행하세요: ./install.sh --new $agent_name"
  link_entry "$card" "$home_dir/.gbrain-agent.md"

  if [ ! -f "$policy_file" ] && [ "$agent_name" != "main" ]; then
    mkdir -p "$home_dir/.local/bin"
    link_entry "$repo_dir/gbrain/bin/gbrain-remote-proxy" "$home_dir/.local/bin/gbrain-$agent_name"
  fi
  echo "GBrain 카드 연결: $agent_name"
}

install_known_project() {
  local agent_name="$1"
  case "$agent_name" in
    main)
      if [ -d "$home_dir/exdigm" ]; then
        install_project_profile "$home_dir/exdigm" exdigm
      fi
      ;;
    fundkeeper)
      if [ -d "$home_dir/fundkeeper" ]; then
        install_project_profile "$home_dir/fundkeeper" fundkeeper
      fi
      ;;
    *)
      if [ -d "$repo_dir/projects/$agent_name" ] && [ -d "$home_dir/$agent_name" ]; then
        install_project_profile "$home_dir/$agent_name" "$agent_name"
      fi
      ;;
  esac
}

verify_agent_install() {
  local agent_name="$1"
  local expected_card="$repo_dir/gbrain-cards/$agent_name.md"
  [ "$(readlink -f "$home_dir/.gbrain-agent.md")" = "$expected_card" ] ||
    die "GBrain 카드 링크 검증에 실패했습니다: $agent_name"

  if [ "$agent_name" = "main" ]; then
    [ -x "$gbrain_cli" ] || die "중앙 GBrain 실행 파일이 없습니다: $gbrain_cli"
    GBRAIN_SOURCE=default "$gbrain_cli" get agent/gbrain-operating-protocol >/dev/null
  else
    local wrapper="$home_dir/.local/bin/gbrain-$agent_name"
    [ -x "$wrapper" ] || die "GBrain 래퍼가 없습니다: $wrapper"
    "$wrapper" policy >/dev/null
  fi
}

install_agent() {
  local agent_name="$1"
  validate_agent_name "$agent_name"
  [ -f "$repo_dir/gbrain-cards/$agent_name.md" ] ||
    die "등록되지 않은 에이전트입니다. 신규 추가: ./install.sh --new $agent_name"

  install_global
  install_gbrain_card "$agent_name"
  install_known_project "$agent_name"
  verify_agent_install "$agent_name"

  echo "설치 완료: $agent_name"
  if [ -d "$backup_root" ]; then
    echo "기존 파일 백업: $backup_root"
  fi
}

render_agent_card() {
  local agent_name="$1"
  printf '%s\n' "- 너는 GBrain 공간 \`$agent_name\`을 쓰는 에이전트다. GBrain 본체는 중앙 서버(\`chaconne@49.247.45.243\`)에 있고, 로컬 \`gbrain-$agent_name\`은 중앙의 정책 래퍼를 호출한다."
  printf '%s\n' "- 작업 전 \`gbrain-$agent_name query \"작업 주제\"\`로 공용 지식과 자기 공간을 함께 조회한다. 명령 문법은 \`gbrain-$agent_name help\`로 확인한다."
  printf '%s\n' "- 사적 기록은 \`gbrain-$agent_name note\` 또는 \`put\`으로 저장한다. 쓰기는 \`$agent_name\` 소스의 \`agents/$agent_name/private/\` 아래로 제한된다."
  printf '%s\n' "- 공용 지식은 읽기 전용이다. 공용 반영이 필요하면 자기 공간에 근거를 기록하고 주인님께 승격을 요청한다."
  printf '%s\n' "- GBrain을 읽지 못하면 프로젝트 판단이 필요한 작업은 중단하고 연결 실패를 보고한다. 단순 상태 확인은 진행할 수 있지만 GBrain 미조회 사실을 함께 알린다."
  printf '%s\n' "- 코드와 GBrain이 다르면 현재 코드를 기준으로 검증하고, 재사용 가치가 있는 확정 사실만 자기 공간에 갱신한다."
}

create_agent_card() {
  local agent_name="$1"
  local card="$repo_dir/gbrain-cards/$agent_name.md"
  if [ -f "$card" ]; then
    echo "기존 GBrain 카드 유지: $card"
    return 1
  fi

  local card_tmp="$card.new-$stamp-$$"
  render_agent_card "$agent_name" > "$card_tmp"
  mv "$card_tmp" "$card"
  echo "GBrain 카드 생성: $card"
  return 0
}

source_path_for_agent() {
  local agent_name="$1"
  "$gbrain_cli" sources list --json | python3 -c '
import json, sys
agent = sys.argv[1]
for source in json.load(sys.stdin).get("sources", []):
    if source.get("id") == agent:
        print(source.get("local_path") or "")
        raise SystemExit(0)
raise SystemExit(1)
' "$agent_name"
}

validate_existing_policy_block() {
  local agent_name="$1" block_type="$2"
  shift 2
  local block expected_line
  block="$(sed -n "/^\[$block_type\.$agent_name\]$/,/^\[/p" "$policy_file")"
  [ -z "$block" ] && return 1
  for expected_line in "$@"; do
    grep -Fqx "$expected_line" <<<"$block" ||
      die "기존 [$block_type.$agent_name] 정책이 예상 값과 다릅니다. 자동으로 덮어쓰지 않습니다: $expected_line"
  done
}

append_policy_blocks() {
  local agent_name="$1" source_dir="$2" add_source_block="$3" add_agent_block="$4"
  local policy_tmp="$policy_file.new-$stamp-$$"
  cp -a "$policy_file" "$policy_tmp"

  if [ "$add_source_block" = yes ]; then
    cat >> "$policy_tmp" <<EOF

[sources.$agent_name]
label = "$agent_name private memory"
path = "$source_dir"
slug_prefixes = ["agents/$agent_name/private"]
visibility = "private"
EOF
  fi

  if [ "$add_agent_block" = yes ]; then
    cat >> "$policy_tmp" <<EOF

[agents.$agent_name]
label = "$agent_name"
private_source = "$agent_name"
private_prefix = "agents/$agent_name/private"
read_sources = ["default", "$agent_name"]
read_prefixes = [
  "agent",
  "feedback",
  "project",
  "reference",
  "shared/common",
  "agents/$agent_name/private"
]
write_sources = ["$agent_name"]
write_prefixes = ["agents/$agent_name/private"]
common_write = false
can_promote = false
EOF
  fi

  cp -a "$policy_file" "$policy_file.backup-$stamp-$$"
  mv "$policy_tmp" "$policy_file"
}

verify_default_source() {
  local current_json
  "$gbrain_cli" sources default default >/dev/null
  current_json="$("$gbrain_cli" sources current --json)"
  python3 -c '
import json, sys
current = json.load(sys.stdin)
if current.get("source_id") != "default" or current.get("tier") != "brain_default":
    raise SystemExit(f"default source verification failed: {current}")
' <<<"$current_json"
  GBRAIN_SOURCE=default "$gbrain_cli" get agent/gbrain-operating-protocol >/dev/null
}

register_agent_central() {
  local agent_name="$1"
  validate_agent_name "$agent_name"
  [ -f "$policy_file" ] || die "이 명령은 중앙 GBrain 정책 파일이 있는 서버에서만 실행할 수 있습니다: $policy_file"
  [ -x "$gbrain_cli" ] || die "GBrain 실행 파일이 없습니다: $gbrain_cli"
  command -v flock >/dev/null 2>&1 || die "flock 명령이 필요합니다."

  local lock_file="$policy_file.lock"
  exec {policy_lock_fd}>"$lock_file"
  flock -x "$policy_lock_fd"

  local source_dir="$gbrain_home/agent-sources/$agent_name"
  local source_block=no agent_block=no
  if validate_existing_policy_block "$agent_name" sources \
    "path = \"$source_dir\"" \
    "slug_prefixes = [\"agents/$agent_name/private\"]" \
    'visibility = "private"'; then
    source_block=yes
  fi
  if validate_existing_policy_block "$agent_name" agents \
    "private_source = \"$agent_name\"" \
    "private_prefix = \"agents/$agent_name/private\"" \
    "read_sources = [\"default\", \"$agent_name\"]" \
    '  "agent",' \
    '  "feedback",' \
    '  "project",' \
    '  "reference",' \
    '  "shared/common",' \
    "  \"agents/$agent_name/private\"" \
    "write_sources = [\"$agent_name\"]" \
    "write_prefixes = [\"agents/$agent_name/private\"]" \
    'common_write = false' \
    'can_promote = false'; then
    agent_block=yes
  fi

  local source_exists=no source_path=""
  if source_path="$(source_path_for_agent "$agent_name")"; then
    source_exists=yes
    if [ "$source_path" != "$source_dir" ] && { [ "$source_block" = no ] || [ "$agent_block" = no ]; }; then
      die "기존 GBrain 소스 경로가 예상과 달라 자동 정책 등록을 중단합니다: ${source_path:-경로 없음}"
    fi
  fi

  if [ "$source_exists" = no ]; then
    mkdir -p "$source_dir"
    "$gbrain_cli" sources add "$agent_name" --path "$source_dir" --name "$agent_name private memory" --no-federated
    echo "GBrain 공간 생성: $agent_name"
  else
    echo "기존 GBrain 공간 유지: $agent_name"
  fi

  verify_default_source

  if [ "$source_block" = no ] || [ "$agent_block" = no ]; then
    append_policy_blocks "$agent_name" "$source_dir" \
      "$([ "$source_block" = no ] && echo yes || echo no)" \
      "$([ "$agent_block" = no ] && echo yes || echo no)"
    echo "GBrain 정책 등록: $agent_name"
  else
    echo "기존 GBrain 정책 유지: $agent_name"
  fi

  install_file "$repo_dir/gbrain/bin/gbrain-agent" "$gbrain_home/bin/gbrain-agent"
  chmod 755 "$gbrain_home/bin/gbrain-agent"
  mkdir -p "$home_dir/.local/bin"
  link_entry "$gbrain_home/bin/gbrain-agent" "$home_dir/.local/bin/gbrain-$agent_name"
  "$home_dir/.local/bin/gbrain-$agent_name" policy >/dev/null
  echo "중앙 GBrain 등록 완료: $agent_name"
}

register_agent() {
  local agent_name="$1"
  if [ -f "$policy_file" ]; then
    register_agent_central "$agent_name"
  else
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$gbrain_host" \
      "/home/chaconne/kmh-agent-kit/install.sh --register-agent $agent_name"
  fi
}

show_new_agent_dry_run() {
  local agent_name="$1"
  validate_agent_name "$agent_name"
  cat <<EOF
[dry-run] 신규 에이전트: $agent_name
[dry-run] GBrain 소스: $agent_name
[dry-run] 전용 경로: agents/$agent_name/private
[dry-run] 카드: $repo_dir/gbrain-cards/$agent_name.md
[dry-run] 중앙 등록: $gbrain_host
[dry-run] 설치 명령: ./install.sh $agent_name
EOF
  echo
  echo "[dry-run] 생성 카드 미리보기"
  render_agent_card "$agent_name"
}

add_new_agent() {
  local agent_name="$1"
  validate_agent_name "$agent_name"

  local card_created=no
  if create_agent_card "$agent_name"; then
    card_created=yes
  fi

  if ! register_agent "$agent_name"; then
    if [ "$card_created" = yes ]; then
      unlink "$repo_dir/gbrain-cards/$agent_name.md"
    fi
    die "중앙 GBrain 등록에 실패했습니다. 로컬 신규 카드는 되돌렸습니다."
  fi

  install_agent "$agent_name"
  echo "에이전트 등록·설치 완료: $agent_name"
  if [ "$card_created" = yes ]; then
    echo "새 카드를 공유하려면 kmh-agent-kit에서 커밋·push하세요: gbrain-cards/$agent_name.md"
  fi
}

case "${1:-}" in
  "")
    [ "$#" -eq 0 ] || die "인수가 올바르지 않습니다. ./install.sh --help"
    install_global
    echo "공용 설치 완료. 전체 설치 명령은 ./install.sh --help에서 서버별로 확인하세요."
    ;;
  -h|--help)
    [ "$#" -eq 1 ] || die "도움말에는 추가 인수를 사용할 수 없습니다."
    show_usage
    ;;
  --project)
    [ "$#" -eq 3 ] || die "사용법: ./install.sh --project ~/exdigm exdigm"
    install_project_profile "$2" "$3"
    ;;
  --gbrain)
    [ "$#" -eq 2 ] || die "사용법: ./install.sh --gbrain rndlog"
    install_agent "$2"
    ;;
  --new)
    if [ "$#" -eq 3 ] && [ "$3" = "--dry-run" ]; then
      show_new_agent_dry_run "$2"
    elif [ "$#" -eq 2 ]; then
      add_new_agent "$2"
    else
      die "사용법: ./install.sh --new abc-project [--dry-run]"
    fi
    ;;
  --register-agent)
    [ "$#" -eq 2 ] || die "내부 사용법: ./install.sh --register-agent abc-project"
    register_agent_central "$2"
    ;;
  --*)
    die "알 수 없는 옵션: $1. ./install.sh --help"
    ;;
  *)
    [ "$#" -eq 1 ] || die "서버 이름은 하나만 입력합니다. ./install.sh --help"
    install_agent "$1"
    ;;
esac
