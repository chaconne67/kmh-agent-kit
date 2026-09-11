# Windows 컨트롤타워

- 이 Windows PC는 전체 프로젝트의 조정실이다. venture는 여러 프로젝트 중 하나이며 로컬에서 실행한다.
- 원격 프로젝트는 Windows에서 조정하고 기존 서버의 코드·Git·검증·배포 경로를 SSH로 사용한다. DB 서버는 DB·GBrain 본체와 ZiiN 운영·개발 저장소를 계속 유지한다.
- 전역 GBrain은 공용 `default` 소스를 사용한다. venture 개인 공간을 전역 기본값으로 사용하지 않는다.
- 프로젝트 지침이 별도 GBrain 카드·개인 공간을 지정하면 그 프로젝트 안에서 해당 설정을 사용한다. 개인 기록을 공용으로 복사하지 않는다.

## 공용 GBrain 실행

DB의 기존 메인 CLI를 Windows에서 SSH로 호출한다. PowerShell과 Git Bash에서 같은 명령을 사용할 수 있다.

```text
ssh chaconne@49.247.45.243 '/home/chaconne/.gbrain/bin/gbrain_with_google_env.sh get agent/gbrain-operating-protocol --source default'
```

- 작업 전 위 운영 프로토콜과 `project/windows-control-tower-operating-context`, 해당 프로젝트의 운영 맥락을 읽는다. `get`의 slug를 필요한 페이지로 바꿔 사용한다.
- 검색은 같은 CLI의 `query '<검색어>' --source-id default`, 목록은 `list --source default`를 사용한다. 명령별 문법은 같은 CLI의 `<명령> --help`로 확인한다.
- 공용 기록은 기존 본문을 읽고 보존한 뒤, 같은 CLI의 `capture --source default --slug <slug> --stdin --json`에 Markdown 본문을 표준입력으로 전달한다. Git Bash에서는 로컬 파일을 `< 파일.md`로 전달할 수 있다.
- 공용에는 프로젝트·공통 운영 지식만 기록한다. 비밀값과 개인 기록을 넣지 않으며, 다른 에이전트의 개인 소스를 전역 검색 대상으로 삼지 않는다.
- GBrain 접근 실패는 실패로 보고한다. 현재 코드·서버와 기록이 다르면 실제 상태를 확인한 뒤 갱신한다.
