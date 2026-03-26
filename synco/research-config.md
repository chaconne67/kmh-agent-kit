# Research Configuration — ga-biz-match

이 파일은 리서치 에이전트 spawn 시 프롬프트에 포함해야 하는 웹검색 설정이다.
`research-principles.md`의 "Handling Research Failures"를 **대체**한다.

---

## 웹검색 Fallback Chain

검색이 필요할 때 아래 순서대로 시도한다. 상위 도구가 성공하면 하위는 건너뛴다.

### 1순위: WebSearch (기본)
- 용도: 빠른 팩트 검색, 키워드 기반
- timeout: **30초**
- 실패 시: 즉시 2순위로

### 2순위: WebFetch (URL 직접 접근)
- 용도: 특정 URL의 내용 추출 (보고서, 기사, 통계 페이지)
- timeout: **30초**
- WebSearch에서 URL을 얻었지만 내용이 부족할 때 사용

### 3순위: grok-web (심층 검색)
- 용도: WebSearch 반복 실패 시, 또는 복잡한 질문에 AI 분석이 필요한 경우
- 실행 방법:
  ```bash
  # 1. Edge CDP 시작 (최초 1회)
  wsl bash -c "bash /home/chaconne/.openclaw/skills/grok-web/scripts/ensure_edge.sh"

  # 2. 질문 전송 (PowerShell 경유)
  /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "cd C:\Users\chaconne; node grok_query.js '질문 내용' 2>&1"
  ```
- timeout: **2분** (스크립트 내장 대기)
- 한국어 질문 가능, 웹검색+AI 분석 결합 응답

### 4순위: 지식 기반 (최후 수단)
- 모든 웹검색이 실패했을 때만 사용
- 반드시 **[Knowledge-Based — not live data, verify independently]** 라벨 부착
- confidence를 한 단계 하향 (High→Medium, Medium→Low)

---

## 에이전트 통제 규칙

| 규칙 | 값 |
|------|-----|
| 개별 검색 timeout | 30초 (WebSearch/WebFetch), 2분 (grok-web) |
| 에이전트당 검색 최대 횟수 | **5회** (모든 도구 합산) |
| 연속 실패 허용 | **3회** → 해당 토픽 지식 기반 전환 |
| Wave당 동시 에이전트 | **최대 3개** |
| 에이전트 전체 실행 timeout | **5분** (초과 시 현재까지 결과로 마감) |

---

## 검색 실패 처리 (research-principles.md 대체)

1. **쿼리 변형 3회** — 동의어, 다른 각도, 영어/한국어 전환
2. **Fallback Chain 순서대로** — WebSearch → WebFetch → grok-web
3. **프록시 데이터** — 정확한 수치가 없으면 상위 시장에서 비율 추정, 계산 과정 명시
4. **갭 선언** — `DATA GAP: [X]에 대한 신뢰할 수 있는 데이터 없음. 가장 가까운 프록시: [Y]. Confidence: Low`
5. **절대 조작 금지** — 데이터가 없으면 없다고 쓴다

---

## 에이전트 프롬프트 템플릿

에이전트 spawn 시 프롬프트 앞에 아래 블록을 삽입:

```
[RESEARCH CONFIG]
- 웹검색 Fallback: WebSearch(30s) → WebFetch(30s) → grok-web(2min) → Knowledge-Based
- 검색 최대 5회/에이전트, 3회 연속 실패 시 지식 기반 전환
- 전체 실행 5분 이내 완료, 초과 시 현재까지 결과로 마감
- grok-web 사용법: wsl bash -c로 ensure_edge.sh 실행 후 powershell.exe로 grok_query.js 호출
- 지식 기반 사용 시 반드시 [Knowledge-Based] 라벨 + confidence 하향
[/RESEARCH CONFIG]
```