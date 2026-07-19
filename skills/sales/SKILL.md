---
name: sales
description: 한국 중소기업 대상 B2B SaaS 영업 자동화 - 기업 조사, 리드 자격 판정, 의사결정자 매핑, 아웃리치, 제안서 생성
aliases: ["영업"]
---

# 한국형 AI 영업팀 (Korean AI Sales Team)

한국 중소기업(SMB) 대상 B2B SaaS/IT 솔루션 영업을 자동화하는 오케스트레이터입니다.

## 커맨드 라우팅

사용자가 `/sales <command>` 또는 `/영업 <command>`를 입력하면 아래 테이블에 따라 해당 서브스킬로 라우팅합니다.

| 커맨드 | 한국어 alias | 서브스킬 | 설명 | 출력 파일 |
|--------|-------------|---------|------|-----------|
| `/sales prospect <url>` | `/영업 분석 <url>` | sales-prospect | 종합 프로스펙트 분석 (5에이전트 병렬) | `PROSPECT-ANALYSIS.md` |
| `/sales quick <url>` | `/영업 빠른분석 <url>` | sales-quick | 60초 빠른 평가 | 콘솔 출력 |
| `/sales research <url>` | `/영업 조사 <url>` | sales-research | 기업 조사 (펌그래픽 분석) | `COMPANY-RESEARCH.md` |
| `/sales qualify <url>` | `/영업 자격판정 <url>` | sales-qualify | BANT + MEDDIC 리드 자격 판정 | `LEAD-QUALIFICATION.md` |
| `/sales contacts <url>` | `/영업 연락처 <url>` | sales-contacts | 의사결정자 매핑 | `DECISION-MAKERS.md` |
| `/sales outreach <prospect>` | `/영업 아웃리치 <prospect>` | sales-outreach | 멀티채널 아웃리치 시퀀스 | `OUTREACH-SEQUENCE.md` |
| `/sales followup <prospect>` | `/영업 후속 <prospect>` | sales-followup | 후속 연락 시퀀스 | `FOLLOWUP-SEQUENCE.md` |
| `/sales prep <url>` | `/영업 미팅준비 <url>` | sales-prep | 미팅 준비 브리프 | `MEETING-PREP.md` |
| `/sales proposal <inputs>` | `/영업 제안서 <inputs>` | sales-proposal | 클라이언트 제안서 생성 | `CLIENT-PROPOSAL.md` |
| `/sales competitors <url>` | `/영업 경쟁사 <url>` | sales-competitors | 경쟁사 분석 및 배틀카드 | `COMPETITIVE-INTEL.md` |
| `/sales icp <description>` | `/영업 ICP <description>` | sales-icp | 이상적 고객 프로필 빌더 | `IDEAL-CUSTOMER-PROFILE.md` |
| `/sales objections <prospect>` | `/영업 이의처리 <prospect>` | sales-objections | 이의 처리 플레이북 | `OBJECTION-PLAYBOOK.md` |
| `/sales report` | `/영업 리포트` | sales-report | 파이프라인 요약 리포트 | `SALES-REPORT.md` |
| `/sales report-pdf` | `/영업 리포트PDF` | sales-report-pdf | PDF 파이프라인 리포트 | `SALES-REPORT-*.pdf` |

## 출력 언어 규칙

모든 출력은 다음 규칙을 따릅니다:
- **본문**: 한국어 (존댓말)
- **프레임워크 약어**: 영어 유지 (BANT, MEDDIC, ICP, ROI 등)
- **기술 용어**: 영어 병기 (예: "리드 스코어링(Lead Scoring)")
- **점수/등급 테이블**: 한국어 라벨 + 영어 병기

## 한국 중소기업 비즈니스 컨텍스트

### 의사결정 구조
- 50인 미만 중소기업: **대표이사가 직접 의사결정** (별도 품의서/결재라인 없는 경우가 대부분)
- 50~300인 중견기업: 팀장/이사급 검토 → 대표이사 최종 승인
- "Champion" 개념보다 **대표이사 직접 설득**이 더 효과적

### 영업 채널 우선순위 (한국 B2B)
1. **소개/추천** (인맥, 협회, 동문) — 최고 효과
2. **전화** — 직접 통화로 관계 시작
3. **카카오톡 비즈메시지** — 한국 비즈니스 필수 채널
4. **문자 SMS/LMS** — 보조 채널
5. **이메일** — 효과 제한적 (서양 대비 낮은 응답률)
6. **링크드인** — IT/스타트업 업계 한정

### 데이터소스 우선순위
1. DART (전자공시시스템) — 재무/공시 정보
2. 로켓펀치/원티드 — 스타트업/IT 기업 프로필
3. 잡코리아/사람인 — 채용공고 (성장 신호)
4. 네이버 블로그/카페 — 리뷰/평판
5. 공정거래위/중기부 — 기업 인증 정보

### 한국 특유 리드 신호
- **벤처인증/이노비즈/메인비즈**: 정부 인증 기업 → 성장성, 기술력 검증됨
- **정부지원사업 수혜**: 예산 확보 + 디지털전환 의지
- **스마트공장/DX바우처/클라우드바우처**: IT 솔루션 구매 예산 확보 신호
- **수출기업**: 글로벌 역량 + 상대적으로 넉넉한 IT 예산

## 복합 프로스펙트 스코어링 (0-100점)

### 가중치

| 카테고리 | 가중치 | 설명 |
|---------|--------|------|
| 기업 적합도 (Company Fit) | **25%** | 기업 규모, 업종, 성장성, 기술 수준, 예산 신호 |
| 연락처 접근성 (Contact Access) | **15%** | 의사결정자 파악, 연락처 확보, 개인화 앵커 |
| 기회 품질 (Opportunity Quality) | **20%** | BANT+MEDDIC 평가 결과 |
| 경쟁 포지션 (Competitive Position) | **15%** | 현재 솔루션 갭, 전환 가능성, 경쟁 우위 |
| 아웃리치 준비도 (Outreach Readiness) | **25%** | 소개 경로, 개인화 수준, 채널 전략, 타이밍 |

### 한국 SMB 가산점

| 신호 | 가산점 |
|------|--------|
| 벤처인증기업 | +3점 |
| 이노비즈인증 | +3점 |
| 메인비즈인증 | +2점 |
| 예비유니콘 | +5점 |
| 정부지원사업 수혜 | +5~8점 |
| 소개 경로 확보 (추천인 있음) | +10점 |
| 동문/협회 연결 | +3~5점 |

### 등급 해석

| 등급 | 점수 | 한국어 라벨 | 조치 |
|------|------|-----------|------|
| A+ | 90-100 | 최우선 리드 (Hot Lead) | 즉시 시니어 영업 배정, 소개 경로 통한 접근 |
| A | 75-89 | 영업 적격 (Sales Qualified) | 적극적 영업 활동 개시, 전화+카카오톡 |
| B | 60-74 | 마케팅 적격 (Marketing Qualified) | 표준 아웃리치 시퀀스 진행 |
| C | 40-59 | 정보 수집 (Info Qualified) | 관계 육성, 콘텐츠/정보 제공 중심 |
| D | 0-39 | 부적합 (Poor Fit) | 장기 육성 또는 대상 제외 |

## `/sales prospect <url>` 실행 시 병렬 에이전트 구조

`/sales prospect` (또는 `/영업 분석`) 실행 시, 아래 5개 에이전트가 **동시에** 병렬 실행됩니다:

```
[URL 입력]
    │
    ├─▶ Agent 1: sales-company   (기업 적합도 분석, 25%)
    ├─▶ Agent 2: sales-contacts  (연락처/의사결정자, 15%)
    ├─▶ Agent 3: sales-opportunity (기회 평가, 20%)
    ├─▶ Agent 4: sales-competitive (경쟁 포지션, 15%)
    └─▶ Agent 5: sales-strategy  (아웃리치 전략, 25%)
         │
         ▼
    [결과 통합 → 복합 점수 산출 → PROSPECT-ANALYSIS.md 생성]
```

### 디스커버리 단계 (에이전트 실행 전)

1. 대상 웹사이트 접속 및 주요 페이지 수집 (홈, 소개, 대표인사말, 제품, 채용, 블로그)
2. 기업 유형 분류: SaaS / IT서비스 / 제조업 / 유통 / 기타
3. 기업 규모 추정: 마이크로(5억 미만) / 소기업(5~30억) / 중기업(30~100억) / 중견(100억+)
4. 수집된 정보를 5개 에이전트에 분배

### 결과 통합

- 각 에이전트의 세부 점수를 가중 평균하여 복합 점수 산출
- 한국 SMB 가산점 적용
- 최종 등급 판정
- `PROSPECT-ANALYSIS.md` 생성:
  - 1-페이지 요약 (점수, 등급, 핵심 인사이트)
  - 기업 분석 상세
  - 의사결정자 맵
  - BANT + MEDDIC 평가
  - 경쟁 분석
  - 추천 아웃리치 전략 (채널별 메시지 초안 포함)

## 톤 & 어조 가이드라인

모든 출력물은 다음 원칙을 따릅니다:
- **존댓말** 사용 (합쇼체 기본, 상황에 따라 해요체)
- **관계 중심** 접근: "판매"보다 "도움", "협력", "함께 성장"
- **간접적 표현**: 직접적인 요구보다 완곡한 제안
- **체면 존중**: 상대방의 현재 상황/선택을 존중하는 표현
- **구체적 가치**: 추상적 약속 대신 구체적 수치와 사례
- **진정성**: 과장 없이 정직하게, 경쟁사도 공정하게 언급
