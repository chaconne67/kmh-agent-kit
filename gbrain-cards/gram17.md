- 너는 GBrain 공간 `gram17`을 쓰는 에이전트다. 이 기기는 **Windows PC**이고, GBrain 본체는 DB 서버(`chaconne@49.247.45.243`)에 있다.
- Windows에는 bash 프록시(`~/.local/bin/gbrain-gram17`)를 둘 수 없다. 모든 명령은 SSH로 서버 래퍼를 직접 호출한다 — 비대화형 SSH의 PATH에 없으므로 **절대 경로 필수**:
  ```
  ssh chaconne@49.247.45.243 '~/.local/bin/gbrain-gram17 <명령> ...'
  ```
  이 PC의 SSH config에는 `DB` alias가 있어 `ssh DB '...'`로도 된다.
- 명령 문법은 `gbrain-gram17 help`로 확인한다. `search`·`show`는 없다 — 읽기 `get <slug>`, 의미검색 `query`/`query-private`/`query-all`, 목록 `list`.
- 쓰기(`note`/`put`)는 gram17 전용 공간(소스 `gram17`, `agents/gram17/private/` 아래)에만 저장된다. 공용(default)에는 직접 쓰지 않는다 — 공용 반영이 필요하면 사적 공간에 기록해 두고 주인님께 승격을 요청한다.
- 공용 소스 페이지(`feedback/...`, `reference/...` 등)는 gram17 네임스페이스 밖이라 `gbrain-gram17 get`으로 읽지 못한다. 서버의 `gbrain`으로 읽는다:
  ```
  ssh chaconne@49.247.45.243 'export PATH=$HOME/.bun/bin:$HOME/.local/bin:$PATH; GBRAIN_SOURCE=default gbrain get <slug>'
  ```
- 새 세션 시작 또는 작업 전 필수 실행:
  - `ssh DB '~/.local/bin/gbrain-gram17 get agents/gram17/private/machine-context'`
- 필수 문서를 읽은 뒤, 작업 주제의 기능명·모델명·화면명·오류명으로 GBrain을 추가 검색한다.
- GBrain이 안 되면:
  - 프로젝트 판단이 필요한 작업은 멈추고 실패를 보고한다.
  - 단순 파일 확인, 명확한 사용자 지시, 상태 확인, 테스트 실행은 진행하되, GBrain을 읽지 못했다는 사실을 함께 보고한다.
- 코드와 GBrain이 다르면 **코드가 기준**. 검증 후 GBrain을 갱신한다.
- 이 기기는 여러 프로젝트(FundKeeper·테스트베드 등)를 오가는 작업용 PC다. 프로젝트 고유 지식은 그 프로젝트 전용 공간(`fundkeeper` 등)이 정본이며, gram17 공간에는 **이 기기에 한정된 것**만 저장한다 — 로컬 경로·설치 상태·기기 고유 제약(Windows 인코딩, 심링크 불가 등)·원격 접속 구성.
- 작업·대화 중 재사용 가치가 있는 규칙, 구조, 발견, 결정은 별도 지시가 없어도 판단 즉시 저장한다. 대화 단위가 아니라 기능·도메인·규칙 단위로 짧게 저장한다.
- 저장 위치: 기기 환경·설치 상태·경로 변경은 `agents/gram17/private/machine-context`에 반영한다. 일반 작업 규칙은 GBrain이 아니라 이 카드 수정으로 반영한다.
- 저장 후 어느 페이지에 반영했는지 답변에 짧게 남긴다. 단순 실행 로그, 일회성 결과, 코드로 바로 확인 가능한 장황한 목록은 저장하지 않는다.
