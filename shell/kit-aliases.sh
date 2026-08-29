# kmh-agent-kit 일상 동기화 명령.
# 최초 설치가 Git 로컬 설정에 저장한 등록 이름으로 공용 자산과 해당 도메인을 자동 선택한다.

unalias kitpull kitpush 2>/dev/null || true
unset -f kitpull kitpush 2>/dev/null || true

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
        echo "기존 GBrain 카드에서 등록 이름 복구: $agent" >&2
        ;;
      *)
        echo "ERROR: 등록 이름이 없습니다. 최초 설치 명령을 실행하세요: $kit/install.sh <등록 이름>" >&2
        return 1
        ;;
    esac
  fi

  [[ "$agent" =~ ^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$ ]] || {
    echo "ERROR: 잘못된 등록 이름: $agent" >&2
    return 1
  }
  [ -f "$kit/gbrain-cards/$agent.md" ] || {
    echo "ERROR: 등록 이름에 해당하는 GBrain 카드가 없습니다: $agent" >&2
    return 1
  }
  printf '%s\n' "$agent"
}

_kit_domain_for_agent() {
  local agent="$1"
  case "$agent" in
    main) printf '\n' ;;
    fundkeeper) printf '%s\n' fundkeeper ;;
    *) printf '%s\n' "$agent" ;;
  esac
}

_kit_path_allowed() {
  local path="$1" agent="$2" domain="$3"

  [ "$agent" = main ] && return 0
  case "$path" in
    gbrain-cards/*) [ "$path" = "gbrain-cards/$agent.md" ] ;;
    skills/domains/*) [ -n "$domain" ] && [[ "$path" == "skills/domains/$domain/"* ]] ;;
    projects/*) [ -n "$domain" ] && [[ "$path" == "projects/$domain/"* ]] ;;
    *) return 0 ;;
  esac
}

_kit_assert_push_scope() {
  local kit="$1" agent="$2" domain="$3" remote_ref="$4"
  local path invalid=no

  while IFS= read -r -d '' path; do
    [ -n "$path" ] || continue
    if ! _kit_path_allowed "$path" "$agent" "$domain"; then
      printf 'ERROR: 현재 등록(%s)의 push 범위 밖 변경: %s\n' "$agent" "$path" >&2
      invalid=yes
    fi
  done < <({
    git -C "$kit" diff --name-only --no-renames -z
    git -C "$kit" diff --cached --name-only --no-renames -z
    git -C "$kit" ls-files --others --exclude-standard -z
    git -C "$kit" log --format= --name-only --no-renames -z "$remote_ref"..HEAD --
  })

  if [ "$invalid" = yes ]; then
    echo "ERROR: 공용 파일과 매칭 도메인${domain:+($domain)}만 kitpush할 수 있습니다." >&2
    return 1
  fi
}

_kit_assert_main_path() {
  local kit="$1" branch state git_path

  branch="$(git -C "$kit" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [ "$branch" != main ]; then
    if [ -z "$branch" ]; then
      echo "ERROR: kmh-agent-kit가 detached HEAD 상태입니다. main 브랜치로 복구한 뒤 다시 실행하세요." >&2
    else
      echo "ERROR: kitpull·kitpush는 main 브랜치에서만 실행합니다. 현재 브랜치: $branch" >&2
    fi
    return 1
  fi

  for state in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    git_path="$(git -C "$kit" rev-parse --git-path "$state")"
    case "$git_path" in
      /*|[A-Za-z]:/*) ;;
      *) git_path="$kit/$git_path" ;;
    esac
    if [ -e "$git_path" ]; then
      echo "ERROR: 진행 중인 Git 작업($state)을 먼저 끝내거나 취소하세요." >&2
      return 1
    fi
  done
}

_kit_fetch_main() {
  local kit="$1"

  git -C "$kit" fetch --quiet --prune origin || return 1
  git -C "$kit" show-ref --verify --quiet refs/remotes/origin/main || {
    echo "ERROR: 원격 origin/main 브랜치가 없습니다." >&2
    return 1
  }
  git -C "$kit" branch --set-upstream-to=origin/main main >/dev/null || return 1
}

_kit_worktree_dirty() {
  [ -n "$(git -C "$1" status --porcelain=v1 --untracked-files=normal)" ]
}

_kit_run_installer() {
  local kit="$1" agent="$2"
  "$kit/install.sh" "$agent"
}

kitpull() {
  local kit="$HOME/kmh-agent-kit"
  local agent counts ahead behind

  agent="$(_kit_registered_agent)" || return 1
  _kit_assert_main_path "$kit" || return 1
  if _kit_worktree_dirty "$kit"; then
    echo "ERROR: 로컬 변경이 있습니다. 먼저 kitpush를 실행하세요." >&2
    return 1
  fi

  _kit_fetch_main "$kit" || return 1
  read -r ahead behind < <(git -C "$kit" rev-list --left-right --count HEAD...origin/main)
  if [ "$ahead" -gt 0 ]; then
    echo "ERROR: 아직 push하지 않은 로컬 커밋이 있습니다. kitpush를 실행하세요." >&2
    return 1
  fi
  if [ "$behind" -gt 0 ]; then
    git -C "$kit" merge --ff-only origin/main || return 1
  fi

  _kit_run_installer "$kit" "$agent"
}

kitpush() {
  local kit="$HOME/kmh-agent-kit"
  local agent domain message

  agent="$(_kit_registered_agent)" || return 1
  domain="$(_kit_domain_for_agent "$agent")"
  message="${1:-Update $agent agent kit}"

  _kit_assert_main_path "$kit" || return 1
  _kit_fetch_main "$kit" || return 1
  _kit_assert_push_scope "$kit" "$agent" "$domain" origin/main || return 1

  _kit_run_installer "$kit" "$agent" || return 1
  _kit_assert_push_scope "$kit" "$agent" "$domain" origin/main || return 1
  git -C "$kit" status --short
  git -C "$kit" add -A || return 1
  _kit_assert_push_scope "$kit" "$agent" "$domain" origin/main || return 1
  git -C "$kit" diff --cached --quiet || git -C "$kit" commit -m "$message" || return 1

  if ! git -C "$kit" merge-base --is-ancestor origin/main HEAD; then
    if ! git -C "$kit" rebase origin/main; then
      git -C "$kit" rebase --abort >/dev/null 2>&1 || true
      echo "ERROR: 원격 변경과 충돌했습니다. 로컬 커밋은 보존했습니다. 충돌 내용을 정리한 뒤 kitpush를 다시 실행하세요." >&2
      return 1
    fi
  fi

  _kit_assert_push_scope "$kit" "$agent" "$domain" origin/main || return 1
  _kit_run_installer "$kit" "$agent" || return 1
  if ! git -C "$kit" push origin main:main; then
    echo "ERROR: push 중 원격이 다시 변경됐을 수 있습니다. kitpush를 다시 실행하세요." >&2
    return 1
  fi
}
