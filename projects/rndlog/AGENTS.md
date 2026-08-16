# RNDLOG 중앙 조정실

## 역할

- 이 폴더는 RNDLOG의 에이전트 지침·고유 스킬·장기 기억만 관리합니다.
- 애플리케이션 코드와 고객사 자료는 운영 서버의 저장소에서 관리합니다.
- 중앙 에이전트가 SSH로 원격 저장소를 수정·검증하고 Git을 관리합니다.
- 중앙의 기존 `/home/chaconne/rndlog` 복제본은 공식 작업 경로로 사용하지 않습니다.

## 정본

| 항목 | 값 |
|---|---|
| SSH | `chaconne@49.247.207.147` |
| 호스트명 | `rndlog` |
| 실제 저장소 | `/home/chaconne/rndlog` |
| 호환 경로 | `/home/work/rndnote` → 실제 저장소 |
| GitHub | `git@github.com:chaconne67/rndnote.git` |
| 기준 브랜치 | `main` |
| 앱 Python | Docker 이미지 Python 3.13 |
| 호스트 가상환경 | `/home/chaconne/rndlog/.venv` |
| 배포 진입점 | `/home/chaconne/rndlog/deploy.sh` |
| 운영 스택 | `Rndnote` (`Rndnote_app`, `Rndnote_nginx`) |
| 운영 도메인 | `https://rndlog.kr` |
| 운영 DB | 중앙 서버 `CentralDB_postgres`의 `ceo_loan`, SSH 터널 `127.0.0.1:15432` |

현재 코드·서버와 이 문서가 다르면 실제 상태를 확인해 코드와 서버에 맞춰 이 문서와 GBrain을
갱신합니다. `Rndnote`와 `rndnote.git`은 남아 있는 운영 식별자이며 제품 이름은 RNDLOG입니다.

## 제품 경계

- 공개 영역은 RNDLOG 랜딩, 상담 신청, KOITA 자가진단입니다.
- 로그인 영역은 기업자금 TM·영업 업무를 제공합니다.
- 제품 맥락의 정본은 원격 저장소의 `CONTEXT.md`입니다.
- R&D 증빙 고객사 작업 공간은 원격 저장소의 `clients/`입니다.
- 앱의 공식 DB는 `ceo_loan` 하나이며 RNDLOG 업무 테이블은 `rndlog` 스키마에 둡니다.

## 작업 전 GBrain

GBrain은 중앙 서버에서 사용합니다. `~/.gbrain-agent.md`를 먼저 읽고 다음 문서를 확인합니다.

- `project/rndlog-operating-context`
- 작업 기능명·화면명·모델명으로 찾은 관련 페이지

## 공식 작업 경로

1. GBrain과 원격 저장소의 Git 상태를 확인합니다.
2. 기존 변경과 미추적 파일을 확인하고 그대로 보존합니다.
3. 요청과 관련된 원격 코드·설정·호출 경로를 읽습니다.
4. SSH를 통해 원격 저장소의 요청 범위만 수정합니다.
5. 원격 가상환경에서 영향 범위에 맞는 검증을 실행합니다.
6. 전체 diff와 검증 결과를 확인하고 요청 범위만 커밋합니다.
7. 배포는 주인님이 명시적으로 요청한 경우에만 실행합니다.
8. 배포 후 HTTPS와 Swarm 서비스 상태를 확인합니다.

`deploy.sh`는 저장소의 모든 변경과 미추적 파일을 한 배포 단위로 커밋할 수 있습니다. 함께
배포할 수 없는 기존 변경이 하나라도 있으면 배포하지 말고 주인님께 범위를 보고합니다.

## 고유 스킬

- 고객사 R&D 증빙 조사·HTML 작성·PDF 생성: `rndlog`
- RNDLOG 제품 UI·템플릿·Tailwind·HTMX·반응형·접근성: `rndlog-design-system`

두 스킬은 RNDLOG 조정실에서만 노출합니다. 고객사 PDF 서식과 제품 UI 디자인 시스템을 서로
섞지 않으며, 일반 코딩이나 배포라는 이유만으로 발동하지 않습니다.

## 검증 기준

- Django 검사: `cd /home/chaconne/rndlog && /home/chaconne/.local/bin/uv run python manage.py check --settings=main.settings.local`
- 관련 테스트: `/home/chaconne/rndlog/.venv/bin/pytest <대상>`
- 템플릿 변경은 Tailwind 빌드와 `collectstatic` 후 실제 화면을 확인합니다.
- 제품 화면은 `rndlog-design-system` 스킬에 따라 모바일·데스크톱과 상호작용 상태를 확인합니다.
- 고객사 PDF는 `rndlog` 스킬의 WeasyPrint 경로로 생성하고 누락 파일이 없는지 확인합니다.
- 운영 확인은 `https://rndlog.kr` 응답과 `Rndnote_app`, `Rndnote_nginx`의 `1/1` 상태를 사용합니다.
- 검증하지 못한 항목을 통과했다고 보고하지 않습니다.

## 안전 경계

- `clients/*/inputs/`의 고객사 원본은 수정하지 않습니다.
- 확인되지 않은 회사 정보·연구원·수치·논문·기관명을 만들지 않습니다.
- 고객사 자료, `.env`, `.credential`, 운영 DB, 문자 발송, 예약 작업, Docker Swarm은 요청 없이
  변경하지 않습니다.
- 테스트와 관리 명령이 운영 DB·SOLAPI·Google·Telegram에 미치는 영향을 먼저 확인합니다.
- 원격 저장소의 기존 변경과 미추적 파일을 삭제하거나 덮어쓰지 않습니다.
- 운영 서버의 에이전트 설정은 이번 중앙 조정실에서 관리하지 않습니다.

## Git 경계

- 원격 저장소와 SSH 인증이 Git 작업의 정본입니다.
- 기준 브랜치는 `main`이고 GitHub 저장소 이름은 아직 `rndnote`입니다.
- 강제 push, 운영 파일 복사 배포, 일부 변경만 숨긴 부분 배포를 하지 않습니다.
