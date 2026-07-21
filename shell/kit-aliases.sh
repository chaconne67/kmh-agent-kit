# kmh-agent-kit 셸 별칭 — install.sh가 ~/.bashrc에 source 라인을 추가한다.
# 편집은 아무 경로에서나(심링크), 커밋·푸시는 반드시 키트 레포 지정으로.

# 이전에 수동으로 정의한 동명 alias가 있으면 함수 정의 파싱이 깨지므로 먼저 해제한다.
unalias kitinstall kitpull kitpush 2>/dev/null

alias kitinstall='git clone git@github.com:chaconne67/kmh-agent-kit.git ~/kmh-agent-kit && cd ~/kmh-agent-kit && ./install.sh'

# pull 후 install.sh 재실행(멱등) — 스킬 추가·삭제 반영과 링크 정리를 자동화
alias kitpull='git -C ~/kmh-agent-kit pull --ff-only && ~/kmh-agent-kit/install.sh'

# 사용: kitpush "커밋 메시지"  (생략 시 기본 메시지)
kitpush() {
  git -C ~/kmh-agent-kit status --short
  git -C ~/kmh-agent-kit add -A \
    && git -C ~/kmh-agent-kit commit -m "${1:-Update agent kit}" \
    && git -C ~/kmh-agent-kit push
}
