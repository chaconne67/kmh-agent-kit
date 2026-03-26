# Verification Report: ga-biz-match
*Generated: 2026-03-25*

## Summary
- **Critical issues:** 3
- **Warnings:** 7
- **Info:** 4

---

## Critical Issues

### C1. 가격 수치 파일 간 불일치 (Internal Contradiction)
- **market-analysis.md**: SAM 산출 시 "월 5~10만원" 사용 (line 28), SOM 시나리오에서 기본 ARPU "월 7만원" (line 36)
- **target-audience.md**: 권장 가격 모델에서 Pro "월 3.9만원", Enterprise "설계사당 월 1.5~2만원" (line 153-156), 가격 민감도 심리적 한계 "월 2.9만원 이하" (line 113)
- **문제:** market-analysis의 SAM/SOM은 월 5~10만원 기준으로 산출했으나, target-audience의 실제 WTP와 권장 가격은 1.5~3.9만원대. SOM 8.4억원(1,000명 x 7만원)은 WTP 분석과 정면 충돌. Enterprise 모델(1.5~2만원) 기준이면 SOM은 1.8~2.4억원으로 급감.
- **영향:** 매출 전망 과대평가로 의사결정 오류 가능

### C2. SAM 핵심 변수 미검증 상태에서 Medium Confidence 부여 (Confidence Overrating)
- **market-analysis.md**: SAM 600~1,500억원에 "Confidence: Medium" 부여 (line 30)
- **confidence-dashboard.md**: 법인영업 설계사 비중 30~40%를 "Low" (corroborating sources: 0)로 정확히 평가
- **문제:** SAM의 핵심 입력변수(법인영업 비중)가 Low confidence인데, 산출 결과인 SAM이 Medium이 될 수 없음. 입력이 Low이면 출력도 Low여야 함.

### C3. 비즈니스 매칭 수수료 규모 태그 누락 및 근거 부재
- **market-analysis.md** line 29: "비즈니스 매칭 수수료: 추가 수백억원 (검증 필요) [Assumption]"
- **문제:** "수백억원"의 산출 근거가 전혀 없음. SAM에 포함된 수치인데 어떤 거래량/건당 금액으로 도출했는지 불명. confidence-dashboard에서도 "비즈매칭 거래 건당 규모: 데이터 없음"으로 인정.

---

## Warnings

### W1. INFORYOU 동일 소스 반복 참조
- competitor-landscape.md (line 24)와 industry-trends.md (line 57), confidence-dashboard.md (line 27) 모두 INFORYOU $13.5M 투자를 언급
- 모든 파일이 동일한 단일 Tier 3 소스(WOWTALE)에 의존하면서 "교차검증 실패"를 명시
- **문제:** 교차검증 실패한 데이터가 3개 파일에 반복 등장하여 신뢰도가 실제보다 높게 느껴질 수 있음

### W2. ~~설계사 수 미세 불일치~~ → **RESOLVED**
- Wave 4 리서치로 FSS 공식 데이터 확보: **288,446명 (2024말, YoY +9.5%)**
- 전체 파일을 288,446명 기준으로 통일 완료

### W3. GA 성장률 둔화 수치 태그 누락
- **market-analysis.md** line 49: "GA 채널 성장률 둔화: 46% → 19% → 5.8% (YoY) [Data]"
- **문제:** [Data] 태그는 있으나, 각 수치의 기준 연도가 명시되지 않음. 언제의 46%이고 언제의 5.8%인지 불명확하여 "성장률 둔화" 내러티브 검증 불가.

### W4. ~~중소형 GA 수 표기 불일치~~ → **PARTIALLY RESOLVED**
- Wave 4 FSS 데이터: GA 법인 4,432개 (2023말), 72개 대형 GA(500명+)에 249,496명
- 중소형 ~4,360개, FC ~38,950명으로 재산출
- 2023→2024 변동은 29,540개 GA 기관 (개인 포함) 기준으로 확인, 법인 기준 2024말 데이터는 미확보

### W5. CRM 프로젝트 실패율 출처 Tier 미표기
- **market-analysis.md** line 50: "CRM 프로젝트 실패율 55% [Data, Johnny Grow]"
- **문제:** Johnny Grow의 Tier 등급이 Sources 섹션에 미포함. 컨설팅 회사의 자체 조사는 통상 Tier 2~3이며, 이 수치가 어느 시점의 데이터인지 불명 (Stale Data 리스크).

### W6. target-audience.md에 정량 클레임 태그 부재 다수
- line 13: "여성 60%/남성 40%" — 태그 없음
- line 33: "남성 80%+" — 태그 없음
- line 47: "1년 내 50%+ 이탈" — 태그 없음
- line 87: "카카오톡 + 엑셀 ~90%" — 태그 없음
- line 88: "GA 자체 시스템 ~10%" — 태그 없음
- **문제:** Claims Without Source 규칙 위반. 이들이 [Data]인지 [Estimate]인지 [Assumption]인지 판별 불가.

### W7. competitor-landscape.md 정량 클레임 태그 부재
- line 23: "인카 1,200명" — 태그 없음 (본문에서는 근거가 있으나 태그 미부착)
- line 61: "오프라인 라운지 24개" — 태그 없음
- line 87-89: 사용 비율(~90%, ~10%, <5%) — 태그 없음

---

## Info

### I1. Data Gaps 섹션 유무
- market-analysis.md: Data Gaps 섹션 있음 (6개 항목 상세)
- competitor-landscape.md: Data Gaps 명시적 섹션 없음 (INFORYOU 불확실성은 Flags에 기재)
- target-audience.md: Data Gaps 명시적 섹션 없음
- industry-trends.md: Data Gaps 명시적 섹션 없음
- confidence-dashboard.md: Critical Unknowns 섹션이 Data Gaps 역할 수행
- **권장:** competitor-landscape, target-audience, industry-trends에 간략한 Data Gaps 섹션 추가

### I2. Stale Data 체크
- 모든 파일의 Data Age가 2025~2026으로 18개월 이내. Stale Data 이슈 없음.
- confidence-dashboard.md에서 Data Age 컬럼을 명시적으로 관리하고 있어 우수.

### I3. Duplicate Sources 체크
- Research and Markets가 market-analysis.md와 industry-trends.md 양쪽에서 AI CRM CAGR 36.1%의 소스로 사용 — 이는 동일 사실의 인용이므로 문제 없음.
- 독립적 교차검증으로 위장된 중복은 발견되지 않음.

### I4. Flags 섹션 완비 확인
- 5개 파일 모두 Red Flags / Yellow Flags 섹션 보유. target-audience와 industry-trends는 "Red Flags: None identified"로 명시.

---

## Verification Checklist

- [ ] **Claims Without Source:** target-audience.md와 competitor-landscape.md에 미태그 정량 클레임 다수 (W6, W7)
- [x] **Internal Contradictions:** 가격/ARPU 불일치 식별 및 플래그 완료 (C1)
- [ ] **Confidence Rating Consistency:** SAM Medium 평가가 Low 입력변수와 불일치 (C2)
- [ ] **Data Gaps Declared:** 3개 파일(competitor-landscape, target-audience, industry-trends)에 명시적 Data Gaps 섹션 부재 (I1)
- [x] **Flags Present:** 5개 파일 모두 Red/Yellow Flags 섹션 보유
- [x] **Stale Data:** 18개월 초과 데이터 없음
- [x] **Duplicate Sources:** 독립 교차검증으로 위장된 중복 소스 없음

### Cross-Phase Consistency Notes
- **TAM/SAM/SOM 정합성:** SAM→SOM 전환률 약 1.3~1.7%로 합리적이나, 가격 전제가 WTP와 충돌 (C1)
- **경쟁 환경 ↔ 시장 분석 정합:** competitor-landscape의 "중소형 GA 언더서브드" 분석이 market-analysis의 beachhead 전략과 일치
- **타겟 고객 페인 ↔ 시장 기회 정합:** target-audience의 "가치 비대칭" 페인이 market-analysis의 비즈매칭 기회와 정확히 연결
- **가격 민감도 ↔ 매출 전망 불일치:** Phase 2(Strategy)에서 반드시 WTP 기반 매출 모델 재산출 필요
