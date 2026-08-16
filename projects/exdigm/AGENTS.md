# Exdigm 중앙 조정실

## 역할

- 이 폴더는 Exdigm의 에이전트 지침·스킬·GBrain 연결 정보만 관리합니다.
- 애플리케이션 소스와 운영 비밀값은 활성 운영 서버에만 둡니다.
- 중앙 에이전트가 SSH로 원격 디버깅 worktree를 수정·검증·Git 관리합니다.
- 원격 Codex·Claude에는 프로젝트 지침·사용자 스킬·GBrain 설정을 설치하지 않습니다.

## 정본

| 항목 | 값 |
|---|---|
| SSH | `chaconne@49.247.202.197` |
| 호스트명 | `exdigm2` |
| 운영 체크아웃 | `/home/chaconne/exdigm` |
| 디버깅 worktree | `/home/chaconne/exdigm-debug` |
| GitHub | `git@github.com:chaconne67/exdigm.git` |
| 배포 브랜치 | `main` |
| 디버깅 Python | `/home/chaconne/exdigm-debug/.venv/bin/python` |
| 디버깅 진입점 | `scripts/debug_workspace.sh` |
| 운영 배포 | `scripts/deploy/deploy.sh prod` |
| 운영 DB 인프라 배포 | `scripts/deploy/deploy.sh db-prod` |
| 운영 도메인 | `https://office.exdigm.com` |

현재 코드·서버와 이 문서가 다르면 현재 상태를 확인해 코드와 서버에 맞춰 이 문서와 GBrain을 갱신합니다.

## 작업 전 GBrain

GBrain은 중앙 서버에서만 사용합니다. `~/.gbrain-agent.md`를 먼저 읽고 다음 정본을 확인합니다.

- `project/exdigm-operating-context`
- `project/exdigm-deploy-workflow`
- `project/exdigm-remote-debug-workflow`
- 작업 기능명·화면명·모델명으로 찾은 관련 페이지

## 공식 작업 경로

1. GBrain과 원격 코드 상태를 확인합니다.
2. 운영 체크아웃이 `main`의 clean 상태인지 확인합니다.
3. 디버깅 worktree의 기존 변경을 확인하고 보존합니다.
4. 디버깅 worktree가 clean일 때만 `origin/main`의 detached HEAD로 갱신합니다.
5. SSH를 통해 디버깅 worktree의 코드만 수정합니다.
6. `scripts/debug_workspace.sh`로 격리된 검증을 실행합니다.
7. 변경을 커밋한 뒤 `scripts/deploy/deploy.sh prod`로 `origin/main`과 운영 체크아웃에 같은 커밋을 반영합니다.
8. HTTPS·Swarm 서비스·운영 작업자 상태를 확인합니다.

운영 체크아웃은 배포와 운영 작업자의 실행 원본입니다. 그 폴더에서 직접 수정하거나 테스트하지 않습니다.

## 디버깅 DB 경계

| 작업 | 공식 명령 | 데이터 경계 |
|---|---|---|
| 운영 데이터 조회 | `scripts/debug_workspace.sh shell-readonly` | `exdigm_debug_ro`의 SELECT만 허용 |
| 쓰기·로그인·마이그레이션 검증 준비 | `scripts/debug_workspace.sh create` | 빈 `exdigm_debug`, `exdigm_debug_test` 생성 |
| Django 검사 | `scripts/debug_workspace.sh check` | 일회성 DB |
| 화면 확인 | `scripts/debug_workspace.sh run` | `127.0.0.1:8443`, SSH 포워딩 전용 |
| 테스트 | `scripts/debug_workspace.sh test [대상]` | 일회성 테스트 DB |
| Tailwind 빌드 | `scripts/debug_workspace.sh css` | 디버깅 worktree의 추적 CSS 갱신 |
| 쓰기 검증 정리 | `scripts/debug_workspace.sh destroy` | 일회성 DB·계정·파일만 삭제 |

- 운영 DB의 `exdigm` 슈퍼유저 계정으로 디버깅하지 않습니다.
- 운영 데이터가 필요한 진단은 조회 전용 경로에서 최소 결과만 확인합니다.
- 쓰기 검증은 합성한 최소 데이터로 수행합니다.
- 디버깅 환경에는 운영 API 키·Telegram·Drive 비밀값·운영 미디어 경로를 연결하지 않습니다.
- `runserver`는 공개 인터페이스에 바인딩하지 않습니다.

## Git 경계

- 운영 체크아웃은 항상 `main`입니다.
- 디버깅 worktree는 Git의 동일 브랜치 중복 체크아웃을 피하기 위해 detached HEAD를 유지합니다.
- 디버깅 커밋의 `origin/main` push는 배포 스크립트가 fast-forward 방식으로 수행합니다.
- push 거절, 운영 dirty 상태, fast-forward 실패를 강제 push나 수동 파일 복사로 우회하지 않습니다.
- 저장소 전체 변경을 확인하고 사용자 변경을 포함한 하나의 검증된 커밋만 배포합니다.

## 코드 탐색과 완료 기준

- 코드 탐색은 원격 디버깅 worktree에서 `uv run --locked python -m tools.code_knowledge code_query`로 시작합니다.
- 테스트는 `scripts/debug_workspace.sh test`를 사용해 공용 잠금과 일회성 테스트 DB를 함께 적용합니다.
- 코드 변경 후 `uv run --locked python -m tools.code_knowledge catalog_update`를 원격 worktree에서 실행합니다.
- UI 변경은 SSH 포워딩으로 같은 `runserver` 화면을 직접 확인합니다.
- 실행 동작·데이터·권한·배포 경로가 바뀌는 변경은 `code-review-loop`를 통과합니다.

## 회사 확장 경계

- 코드 저장소와 빌드 결과는 하나로 관리합니다.
- 회사별 DB·DB 역할·도메인·비밀값·미디어·작업자·외부 연동·백업은 분리합니다.
- 현재 Exdigm DB에 다른 HR 회사 데이터를 함께 넣지 않습니다.
- 공유 DB 멀티테넌시는 별도의 tenant 격리 설계와 검증 없이 도입하지 않습니다.

## 작업별 스킬

- 자동 게시: `auto-posting`
- 이력서·후보자 추출: `data-extraction`
- 화면·디자인 시스템: `exdigm-design`
- Hermes 제품 연동: `exdigm-hermes-agent`
- 추출 파이프라인 검증: `extraction-pipeline-verify`
- 이력서 생성 개선: `resume-evolution-loop`
- 운영 배포: `exdigm-deploy`
