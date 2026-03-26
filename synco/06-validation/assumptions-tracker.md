# Assumptions Tracker

**Phase:** Phase 8 — Validation (v5, 통합 앱 + AI 개인비서 코어)
**Project:** synco
**Date:** 2026-03-26 (세션 6)
**Confidence:** Medium

---

## Critical Assumptions

| # | 가정 | 분류 | 현재 신뢰도 | 검증 방법 | 검증 실험 | 상태 |
|---|------|------|-----------|----------|----------|------|
| A0 | FC와 CEO 모두 AI 개인비서(인맥관리·일정관리·브리핑)에 가치를 느끼고 주 3회+ 지속 사용한다 | Product | **Low** | FC/CEO 사용 로그 + 만족도 인터뷰. MVP Tier 0 활성 사용률 측정 | Exp 0, 2 | 미검증 |
| A1 | CEO가 비즈니스 매칭에 월 5~10만원 WTP가 있다 | Market | **Low→Medium** | 인터뷰 + 컨시어지 MVP 결제. 벤치마크: 리멤버 Black 30만원/년, BNI 약 135~405만원/년 [Data] | Exp 1, 4, 5 | 미검증 (간접 증거 확보) |
| A2 | GA 법인 파트너십으로 FC가 자연 편입되고 CEO 접근 가능 | Market | **Medium→High** | GA 파트너십 체결 + FC 온보딩률 실측. 공동창업자 2개 GA 계약 보유 [Data] | Exp 2, 7 | 부분 검증 (GA 구두 협의 완료) |
| A3 | FC 1명당 CEO 50~200명 가입 가능 | Market | **Low** | 파일럿 GA 실측 | Exp 7 | 미검증 |
| A4 | CEO 무료→유료 전환율 2~5% | Business | **Medium** | B2B SaaS 벤치마크 대비 실측 | Exp 4, 5 | 미검증 |
| A5 | AI 매칭 품질이 CEO 과금을 정당화할 수준 | Product | **Low** | 수동 매칭 vs AI 비교 | Exp 4, 6 | 미검증 |
| A6 | CEO가 프로필을 80%+ 완성한다 (40%+ 달성) | Product | **Low** | 컨시어지 MVP 실측 | Exp 4 | 미검증 |
| A7 | 크레딧 단가 5,000원이 적정하다 | Business | **Low** | 가격 A/B 테스트 | Exp 5 | 미검증 |
| A8 | Premium 월 9.9만원이 적정하다 | Business | **Low** | 가격 A/B 테스트 | Exp 5 | 미검증 |
| A9 | FC가 무료 AI 비서에 가치를 느낀다 | Product | **Medium** | FC 사용 빈도 + 만족도 | Exp 2, 7 | 미검증 |
| A10 | 유료 CEO 17명으로 월 BEP 달성 | Financial | **Medium** | 비용 실측 + 매출 실측 | Exp 7 | 미검증 |

---

## Supporting Assumptions

| # | 가정 | 분류 | 현재 신뢰도 | 근거 | 상태 |
|---|------|------|-----------|------|------|
| S1 | GA 협회/GA가 플랫폼에 적대적이지 않다 | Business | **Medium** | GA협회 2035 금융판매전문회사 로드맵과 방향 정렬 [Data] | 미검증 |
| S2 | 법인영업 FC 네트워크가 실제로 활용 가능하다 | Market | **High** | GA FC 288,446명(FSS 2024말), 72개 대형 GA에 249,496명 집중 [Data] | 부분 검증 |
| S3 | 개인정보 위탁 처리가 법적으로 구조화 가능하다 | Legal | **Medium** | B2B 매칭 별도 허가 불요 [Data]. 단 PIPA 2026(매출10% 과징금, 2026.9 시행) 준수 필수 | 미검증 |
| S4 | 월 이탈률 4% 이하 유지 가능하다 | Business | **Medium** | Marketplace 벤치마크 <5% [Data] | 미검증 |
| S5 | AI API 비용이 FC 무료 제공을 지속 가능하게 한다 | Financial | **High** | FC 월 500~2,000원, 1,000명 = 50~200만원 [Estimate] | 미검증 |
| S6 | 모바일 웹으로 50대 CEO에게 충분한 UX 제공 가능 | Product | **Medium** | 카카오톡 내 미니앱 대안 존재 | 미검증 |
| S7 | 2인 사이드 프로젝트로 10주 MVP 개발 가능 | Team | **Medium** | AI 코딩 도구 활용 전제 | 미검증 |

---

## Assumption Dependencies

```
A0 (AI 개인비서 지속 사용) ← 모든 가설의 전제
  ↓
A1 (CEO WTP) ← A5 (매칭 품질) ← A6 (프로필 완성)
     ↑
A2 (GA 파트너십) ← A9 (FC AI/DB가공 가치) ← A3 (FC당 CEO 수)
     ↓
A4 (전환율) → A10 (BEP) → A7, A8 (가격)
```

> **핵심 의존 체인:** A0(AI 개인비서 지속 사용)이 전체 모델의 기반. 기본 기능이 만족스럽지 않으면 사용자가 떠나고 매칭까지 도달 불가. A0 → A1(CEO WTP)이 핵심 검증 순서.

---

## 검증 우선순위

1. **A0** (Week 1-3) — AI 개인비서 지속 사용이 전체 모델의 전제. Tier 0 실패 시 모든 가설 기각.
2. **A1** (Week 1-5) — CEO WTP가 유일한 치명적 미검증 가정. A2(GA 파트너십)는 공동창업자 GA로 부분 검증됨.
3. **A6 + A5** (Week 3-5) — 프로필 완성 → 매칭 품질. 서비스 가치의 전부.
4. **A7 + A8** (Week 5-6) — 가격 최적화. WTP 존재 확인 후.
5. **A3 + A4** (Week 8-10) — 스케일 가능성. 파일럿 GA 확장으로 검증.

---

## Flags

**Red Flags:** None

**Yellow Flags:**
- Critical Assumptions 10개 중 신뢰도 Low가 6개 — A2(GA 파트너십) Medium→High 상향으로 개선
- A2 리스크 감소가 전체 모델 안정성을 크게 높임 — "FC가 CEO를 데려온다"가 아닌 "GA 파트너십으로 FC+CEO 동시 확보"
- A1(CEO WTP)이 Low이면서 모델의 핵심 축 — A2(GA 파트너십)는 Medium→High로 상향되었으나, A1의 조기 검증이 프로젝트 생사를 결정
