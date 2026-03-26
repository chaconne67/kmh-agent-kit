# synco — AI 개인비서 & 비즈니스 매칭 플랫폼

**Version:** v5 (통합 앱 + AI 개인비서 코어)
**Date:** 2026-03-26 (세션 6)

---

## 한 줄 요약

**데이터에 맥락이 없는 것이 문제다.** AI 개인비서가 인맥과 일정을 알아서 관리하고, 데이터의 many-to-many 관계에서 숨겨진 연결을 발견한다. 놀고 있던 유휴 자산의 가치가 증폭된다. synco는 하나의 앱으로 이 전환을 만드는 플랫폼이다.

---

## 이야기 구조

### 1. 문제 — 데이터에 맥락이 없다
GA가 매년 수천만 원 들여 사는 기업정보를 FC가 받아서 하는 일: "아, 제조업이네. 전화해보자. 사장님 보험 하나 보시죠." **끝.** 28만 FC의 CEO 연락처, GA의 기업정보, CEO의 사업 자원 — 전부 있긴 한데 아무도 제대로 못 쓰고 있다.

### 2. 해결책 — 하나의 앱, AI 개인비서가 기본
**앱은 하나다.** FC든 CEO든 같은 앱을 쓴다. 가입 시 역할만 선택하면 역할에 맞는 화면을 본다. 하나의 DB에서 many-to-many 관계로 연결된다.

**첫 번째 효용은 AI 개인비서다.** 비즈니스 매칭이 아니다.
- ① AI 개인비서로 인맥·일정을 자동 관리 (FC·CEO 동일 — 원천 가치)
- ② 쓰다 보면 AI가 데이터에 맥락을 붙이고 (브리핑)
- ③ many-to-many 관계에서 연결을 발견하고 (매칭)
- ④ FC가 대면으로 성사시키고
- ⑤ 가치가 만들어진 순간에 과금한다

> 기본 기능이 좋아야 다음이 있다. AI 개인비서가 만족스럽지 않으면 매칭까지 도달하지 못한다.

### 3. 시대적 배경 — 왜 지금인가
- AI가 기업정보를 읽고 브리핑을 생성할 수 있는 수준에 도달 (2023년 이전 불가능)
- AI 격차는 지수적 — 대부분은 AI를 구경만 하고 있다. 무료 CRM이 체험의 입구
- 리멤버 2026.3 매칭 런칭 — 시장이 열리고 있다. 같은 방향, 다른 무기(FC 신뢰 채널)
- GA협회 2035 "금융판매전문회사" 로드맵과 정렬

### 4. 확장 전망
기업정보는 첫 번째 대상일 뿐. 활성화된 CEO DB 위에 무한 파생: 딜 중개 수수료 → B2B 광고 → 금융상품 대면 유통(Layer 3)

### 5. 지금 해야 할 일
증명할 것 하나: "AI가 맥락을 붙인 기업정보에 CEO가 돈을 내는가?" → 30일 컨시어지 MVP로 검증

---

## Key Numbers

### Market
- GA FC 288,446명 (FSS 2024말), 법인영업 중심 ~10만명 [Data]
- CEO SAM: 구독 300-900억 + 딜 중개 수수료 500-2,000억 = **800-2,900억원** [Estimate]
- CEO 비즈니스 매칭 벤치마크: BNI 연 약 135~405만원, 리멤버 684억 매출(2024) [Data]

### Competitive Advantage (9/10)
- **CEO 직통 DB**: 돈으로 복제 불가. GA에겐 유휴 자산 → synco가 수익화
- **AI 기업정보 가공**: 숫자 나열 → 맥락 있는 인사이트 전환 = 즉시 가치
- **FC 대면 채널**: AI가 발굴, 사람이 성사 — 콜드 매칭(리멤버)과 근본적 차별화
- **무료 CRM**: AI 체험의 입구 — 격차가 지수적으로 벌어지는 시대에 체험시키는 것 자체가 가치
- GA협회 2035 "금융판매전문회사" 로드맵과 전략 정렬

### Business Model — 3-Layer
- **Layer 1** (진입): FC 무료 AI CRM + CEO 무료 CRM → 데이터 확보
- **Layer 2** (과금): CEO 구독/크레딧 + 딜 중개 수수료 3-10% + B2B 광고
- **Layer 3** (확장): 금융상품 대면 유통 (로보어드바이저, 투자자문 등)
- **BEP: 유료 CEO 17명** — 부트스트랩 가능
- Year 1 매출 예상: ~1.6억 (Base)

### Scorecard: 8.0/10 — Conditional Go (진행 영역 진입)

| 항목 | 점수 | 변동 |
|------|------|------|
| Problem Severity | 7 | |
| Market Size | 8 | |
| Competitive Advantage | **9** | |
| Feasibility | 7 | |
| **Business Model** | **8** | **↑1** (FC 유료화+GA 파트너십+DB 가공) |
| Founder-Market Fit | **9** | |
| Timing | **8** | |

---

## Strategic Positioning

- **핵심 문제:** "데이터에 맥락이 없다" — 가치 없다고 여겨진 데이터를 AI가 가치 있게 바꾼다
- **핵심 차별화:** AI가 발굴하고 사람(FC)이 성사시키는 하이브리드 모델
- **포지셔닝:** "AI가 당신의 데이터에 맥락을 붙여 숨겨진 사업 기회를 발굴합니다"
- **회피:** "보험", "CRM", "인슈어테크" 키워드 — CEO에게 보험 이미지 배제

---

## Top 3 Risks & Mitigation

| # | 리스크 | 영향 | 완화 전략 |
|---|--------|------|----------|
| 1 | **CEO WTP 부재** — 매칭 정보에 돈을 안 낸다 | Critical | Exp 1 인터뷰 + Exp 4 컨시어지 MVP 실제 결제 검증 |
| 2 | **GA 파트너십 실패** — GA가 파트너십에 관심 없음 | High (🟡) | GA 지분/수익 쉐어 제안, DB 가공 가치 입증, 공동창업자 2개 GA 보유 |
| 3 | **PIPA 2026** — 과징금 매출 10%, 2026.9 시행 | Critical | 법률 자문 200-500만원, CEO 직접 가입 구조로 위험 최소화 |

---

## Confidence Dashboard

| 영역 | 신뢰도 | 근거 |
|------|--------|------|
| FC 네트워크 존재 | **High** | GA FC 288,446명, 법인영업 관행 확인 [Data] |
| CEO 직통 DB 자산 | **High** | 공동창업자 3-4천명 DB 보유, 창업자 직접 확인 [Data] |
| 경쟁 환경 | **High** | 리멤버/BNI/매치드 매출·가격 확인 [Data] |
| AI 도입 갭 | **High** | GA 카톡 메모 수준, CEO DB 관리 안 됨 — 창업자 직접 관찰 [Data] |
| CEO WTP | **Low→Medium** | 벤치마크 강화 (리멤버 30만, BNI 120-360만), 직접 데이터 미확보 [Assumption] |
| FC 전환 행동 | **Low** | 수익 쉐어링 동기 추정, 실제 행동 미관찰 [Assumption] |
| 재무 전망 | **Medium** | BEP 17명으로 낮아 실현 가능성 있음 [Estimate] |

---

## Anti-Patterns Detected

- ~~"FC가 CEO를 데려온다" 단일 의존~~ → **해소됨.** DB 소유 주체는 GA(법인). GA 파트너십(지분/수익 쉐어)으로 FC+CEO 접근 동시 해결. 공동창업자 2개 GA 계약 보유.
- **Price-Before-Value 위험** — CEO가 서비스를 경험하기 전에 가격 확정 금지. 컨시어지 MVP에서 가치 경험 후 검증.
- **"무료면 다 쓴다" 환상** — AI CRM에 관심은 있지만 "돈 주고 사는 건 다른 문제." 무료 진입 → 유료 전환의 각 단계마다 별도 검증 필요.

---

## Generated Documents

### 00-intake/
- [brief.md](00-intake/brief.md) — 프로젝트 개요 (스토리텔링 구조: 문제→해결→시대→전망→할일)
- [brainstorm.md](00-intake/brainstorm.md) — 아이디어 7개 변형 탐색

### 01-discovery/
- [market-analysis.md](01-discovery/market-analysis.md) — 시장 규모·성장·규제 (CEO 기반 SAM)
- [competitor-landscape.md](01-discovery/competitor-landscape.md) — 경쟁자 분석 (CEO 관점 대안 포함)
- [target-audience.md](01-discovery/target-audience.md) — FC(Supply) + CEO(Demand) 페르소나
- [industry-trends.md](01-discovery/industry-trends.md) — 산업 트렌드 (AI 도입 갭, 플랫폼 진입 벤치마크)
- [confidence-dashboard.md](01-discovery/confidence-dashboard.md) — 데이터 품질 요약 (창업자 관찰 데이터 포함)
- [raw/](01-discovery/raw/) — 법인영업 실태, CEO WTP, 부분유료화 벤치마크

### 02-strategy/
- [lean-canvas.md](02-strategy/lean-canvas.md) — 린 캔버스 (BEP 17명)
- [value-proposition.md](02-strategy/value-proposition.md) — 가치 제안 (무료 CRM 진입 훅 포함)
- [business-model.md](02-strategy/business-model.md) — 비즈니스 모델 (딜 중개 에스크로 설계 포함)
- [positioning.md](02-strategy/positioning.md) — 포지셔닝 (9개 차별화 요소)
- [go-to-market.md](02-strategy/go-to-market.md) — GTM 전략

### 03-brand/
- [mission-vision-values.md](03-brand/mission-vision-values.md) — 미션·비전·가치
- [tone-of-voice.md](03-brand/tone-of-voice.md) — 톤 앤 보이스
- [brand-personality.md](03-brand/brand-personality.md) — 브랜드 퍼스낼리티

### 04-product/
- [mvp-definition.md](04-product/mvp-definition.md) — MVP 정의 (4개 핵심 가설)
- [feature-prioritization.md](04-product/feature-prioritization.md) — 기능 우선순위
- [user-journey.md](04-product/user-journey.md) — 사용자 여정

### 05-financial/
- [revenue-model.md](05-financial/revenue-model.md) — 수익 모델
- [cost-structure.md](05-financial/cost-structure.md) — 비용 구조
- [projections.md](05-financial/projections.md) — 재무 전망 3 시나리오

### 06-validation/
- [validation-playbook.md](06-validation/validation-playbook.md) — 검증 실험 7개 (비용순, ~40만원/10주)
- [risk-analysis.md](06-validation/risk-analysis.md) — 리스크 매트릭스 (R1-R10)
- [assumptions-tracker.md](06-validation/assumptions-tracker.md) — 가정 추적기 (Critical 10개 + Supporting 7개)
- [experiment-design.md](06-validation/experiment-design.md) — Top 3 실험 상세 설계
- [kill-criteria.md](06-validation/kill-criteria.md) — 중단/피봇 기준 7개
- [scorecard.md](06-validation/scorecard.md) — 아이디어 스코어카드 (7.9/10)

### Other
- [PROGRESS.md](PROGRESS.md) — 프로젝트 진행 추적
- [research-config.md](research-config.md) — 리서치 에이전트 설정
- [action-plan-30-days.md](action-plan-30-days.md) — 30일 액션 플랜
