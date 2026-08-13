# kmh-agent-kit 일상 동기화 명령 — install.sh가 ~/.bashrc에 source 라인을 추가한다.
# 최초 설치가 Git 로컬 설정에 저장한 등록 이름으로 공용 자산과 해당 도메인을 자동 선택한다.

# 이전 정의가 있으면 함수 정의 전에 해제한다.
unalias kitinstall kitpull kitpush 2>/dev/null || true
unset -f kitinstall kitpull kitpush 2>/dev/null || true

_kit_registered_agent() {
  local kit="$HOME/kmh-agent-kit"
  local agent card

  [ -d "$kit/.git" ] || { echo "ERROR: kmh-agent-kit 저장소가 없습니다: $kit" >&2; return 1; }
  agent="$(git -C "$kit" config --local --get kmh-agent-kit.agent 2>/dev/null || true)"

  # 기존 설치는 저장값이 없으므로 현재 카드에서 한 번만 복구한다.
  if [ -z "$agent" ]; then
    card="$(readlink -f "$HOME/.gbrain-agent.md" 2>/dev/null || true)"
    case "$card" in
      "$kit"/gbrain-cards/*.md)
        agent="$(basename "$card" .md)"
        git -C "$kit" config --local kmh-agent-kit.agent "$agent" || return 1
        echo "기존 GBrain 카드에서 서버 등록 이름 복구: $agent" >&2
        ;;
      *)
        echo "ERROR: 서버 등록 이름이 없습니다. 최초 설치 명령을 실행하세요: $kit/install.sh <등록 이름>" >&2
        return 1
        ;;
    esac
  fi

  [[ "$agent" =~ ^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$ ]] || {
    echo "ERROR: 잘못된 서버 등록 이름: $agent" >&2
    return 1
  }
  [ -f "$kit/gbrain-cards/$agent.md" ] || {
    echo "ERROR: 등록 이름에 해당하는 GBrain 카드가 없습니다: $agent" >&2
    return 1
  }
  printf '%s\n' "$agent"
}

_kit_domain_for_agent() {
  local kit="$1" agent="$2"
  case "$agent" in
    main) printf '%s\n' exdigm ;;
    fundkeeper) printf '%s\n' fundkeeper ;;
    *) printf '%s\n' "$agent" ;;
  esac
}

_kit_path_allowed() {
  local path="$1" agent="$2" domain="$3"
  case "$path" in
    gbrain-cards/*) [ "$path" = "gbrain-cards/$agent.md" ] ;;
    skills/domains/*) [ -n "$domain" ] && [[ "$path" == "skills/domains/$domain/"* ]] ;;
    projects/*) [ -n "$domain" ] && [[ "$path" == "projects/$domain/"* ]] ;;
    *) return 0 ;;
  esac
}

_kit_assert_push_scope() {
  local kit="$1" agent="$2" domain="$3"
  local path invalid=no upstream
  upstream="$(git -C "$kit" rev-parse --verify '@{upstream}' 2>/dev/null || true)"

  while IFS= read -r -d '' path; do
    if ! _kit_path_allowed "$path" "$agent" "$domain"; then
      printf 'ERROR: 현재 서버(%s)의 push 범위 밖 변경: %s\n' "$agent" "$path" >&2
      invalid=yes
    fi
  done < <({
    git -C "$kit" diff --name-only --no-renames -z
    git -C "$kit" diff --cached --name-only --no-renames -z
    git -C "$kit" ls-files --others --exclude-standard -z
    if [ -n "$upstream" ]; then
      git -C "$kit" diff --name-only --no-renames -z "$upstream"..HEAD
    fi
  })

  if [ "$invalid" = yes ]; then
    echo "ERROR: 공용 파일과 매칭 도메인${domain:+($domain)}만 kitpush할 수 있습니다." >&2
    return 1
  fi
}

_kit_require_push_base() {
  local kit="$1" upstream
  git -C "$kit" fetch --quiet || return 1
  upstream="$(git -C "$kit" rev-parse --verify '@{upstream}' 2>/dev/null || true)"
  if [ -z "$upstream" ]; then
    echo "ERROR: 현재 브랜치의 원격 추적 브랜치가 없습니다." >&2
    return 1
  fi
  if ! git -C "$kit" merge-base --is-ancestor "$upstream" HEAD; then
    echo "ERROR: 원격 변경이 먼저 있습니다. kitpull로 받은 뒤 kitpush를 다시 실행하세요." >&2
    return 1
  fi
}

kitpull() {
  local kit="$HOME/kmh-agent-kit"
  local agent
  agent="$(_kit_registered_agent)" || return 1
  git -C "$kit" pull --ff-only || return 1
  "$kit/install.sh" "$agent"
}

kitpush() {
  local kit="$HOME/kmh-agent-kit"
  local agent domain
  agent="$(_kit_registered_agent)" || return 1
  domain="$(_kit_domain_for_agent "$kit" "$agent")"
  _kit_require_push_base "$kit" || return 1
  _kit_assert_push_scope "$kit" "$agent" "$domain" || return 1

  "$kit/install.sh" "$agent" || return 1
  git -C "$kit" status --short
  git -C "$kit" add -A
  git -C "$kit" diff --cached --quiet || git -C "$kit" commit -m "${1:-Update $agent agent kit}" || return 1
  git -C "$kit" push
}
