# Moved to Controlroom

지침·스킬·도구와 프로젝트 기획 문서를 [Controlroom](https://github.com/chaconne67/controlroom)으로 통합했습니다. 앞으로의 수정과 동기화는 새 저장소에서 진행합니다. 이 저장소는 이전 이력을 보존하는 보관본입니다.

## 새 장비 설치

GitHub 읽기 인증을 준비한 뒤 Windows Git Bash, macOS Terminal 또는 Linux Bash에서 실행합니다.

```bash
git clone https://github.com/chaconne67/controlroom.git ~/controlroom
bash ~/controlroom/install.sh windows-control
```

설치 후 터미널을 새로 열고 다음 명령을 사용합니다.

```bash
controlroom pull
controlroom push "변경 설명"
```

새 설치는 기존 `kitpull`·`kitpush`도 호환 명령으로 제공합니다. 기존 장비의 옛 저장소에 미전송 변경이 있으면 먼저 확인해 통합하고, 새 저장소의 [장비 준비 안내](https://github.com/chaconne67/controlroom/blob/main/docs/onboarding-new-server.md)를 따릅니다. 기존 폴더와 인증 정보를 삭제하지 마세요.
