---
name: sales-report-pdf
description: PDF 형식 파이프라인 리포트 생성 - generate_pdf_report.py를 활용한 전문 PDF 보고서
aliases: ["영업-리포트PDF"]
---

# PDF 파이프라인 리포트 (PDF Sales Report)

파이프라인 분석 결과를 전문적인 PDF 형식의 보고서로 생성하는 스킬입니다. `generate_pdf_report.py` 스크립트를 호출하여 인쇄/공유에 적합한 보고서를 만듭니다.

## 사용법

```
/sales report-pdf
/영업 리포트PDF
```

## 출력 파일

`SALES-REPORT-[날짜].pdf`

---

## 사전 요구사항

### 필수 패키지

PDF 생성에 필요한 Python 패키지가 설치되어 있어야 합니다.

```bash
uv pip install reportlab matplotlib pandas
```

### 필수 파일

- `generate_pdf_report.py` — PDF 생성 스크립트
- `SALES-REPORT.md` — 파이프라인 리포트 (없으면 `/sales report`를 먼저 실행)

---

## 실행 절차

### 1단계: 사전 확인

#### 1-1. SALES-REPORT.md 존재 확인
- 현재 디렉토리에 `SALES-REPORT.md`가 있는지 확인하십시오.
- 없으면 `/sales report`를 먼저 실행하여 생성하십시오.

#### 1-2. Python 환경 확인
- `generate_pdf_report.py` 스크립트가 존재하는지 확인하십시오.
- 필요한 패키지가 설치되어 있는지 확인하십시오.

```bash
python -c "import reportlab, matplotlib, pandas; print('패키지 확인 완료')"
```

패키지가 없으면 설치하십시오:

```bash
uv pip install reportlab matplotlib pandas
```

### 2단계: PDF 생성

#### 데모 모드 (Demo Mode)

분석 데이터 없이 샘플 데이터로 PDF 형식을 미리 확인하고 싶을 때 사용합니다.

```bash
python generate_pdf_report.py --demo
```

데모 모드 출력:
- 파일명: `SALES-REPORT-DEMO.pdf`
- 내용: 가상의 3개 프로스펙트 데이터로 구성된 샘플 리포트
- 용도: PDF 레이아웃 및 디자인 확인용

#### 커스텀 모드 (Custom Mode)

실제 분석 데이터를 기반으로 PDF를 생성합니다.

```bash
python generate_pdf_report.py --input SALES-REPORT.md --output SALES-REPORT-[날짜].pdf
```

커스텀 모드 옵션:

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--input` | 입력 마크다운 파일 경로 | `SALES-REPORT.md` |
| `--output` | 출력 PDF 파일 경로 | `SALES-REPORT-[날짜].pdf` |
| `--title` | 리포트 제목 | "세일즈 파이프라인 리포트" |
| `--author` | 작성자 | 시스템 사용자명 |
| `--logo` | 회사 로고 이미지 경로 | 없음 (텍스트 로고 사용) |
| `--lang` | 언어 | `ko` (한국어) |

### 3단계: 결과 확인

PDF 생성 완료 후 아래 정보를 콘솔에 출력하십시오.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 PDF 리포트 생성 완료

파일: SALES-REPORT-[날짜].pdf
크기: [X] KB
페이지: [N] 페이지
생성 시간: [X]초

포함된 섹션:
  ✅ 요약
  ✅ 파이프라인 대시보드
  ✅ 점수 분포 차트
  ✅ 상위 프로스펙트 상세
  ✅ 실행 항목
  ✅ 아웃리치 현황
  ✅ 파이프라인 건강도
  ✅ 주간 포커스
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## PDF 보고서 구성

### 페이지 구성

| 페이지 | 내용 |
|--------|------|
| 표지 | 리포트 제목, 날짜, 작성자, 회사 로고 |
| 1-2 | 요약 + 파이프라인 대시보드 |
| 3 | 점수 분포 차트 (막대 그래프 + 파이 차트) |
| 4-5 | 상위 프로스펙트 상세 카드 |
| 6 | 실행 항목 테이블 |
| 7 | 아웃리치 현황 + 채널별 통계 |
| 8 | 파이프라인 건강도 + 주간 포커스 |

### 한국어 포맷팅 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 날짜 | YYYY년 MM월 DD일 | 2026년 03월 13일 |
| 금액 | X,XXX만원 또는 X억원 | 5,000만원, 3억원 |
| 비율 | XX.X% | 75.5% |
| 점수 | XX/100 | 85/100 |
| 등급 | 알파벳 + 한국어 설명 | S등급 (최우선) |
| 폰트 | 본문: 나눔고딕/맑은고딕, 제목: 나눔고딕 Bold | |
| 색상 | 기업용 보수적 색상 (남색, 회색 계열) | |

### 차트 스타일

- **파이프라인 퍼널**: 수평 막대 차트 — 단계별 프로스펙트 수
- **점수 분포**: 히스토그램 — 등급별 분포
- **채널 효과**: 누적 막대 차트 — 채널별 발송/응답/전환
- **건강도 게이지**: 반원형 게이지 — 주요 지표별

---

## 오류 처리

### generate_pdf_report.py가 없는 경우

```
⚠️ generate_pdf_report.py 스크립트가 발견되지 않았습니다.

PDF 생성 스크립트를 먼저 설치해 주세요.
대안으로 SALES-REPORT.md 파일을 마크다운 뷰어에서 확인하실 수 있습니다.
```

### 패키지 미설치 시

```
⚠️ PDF 생성에 필요한 패키지가 설치되어 있지 않습니다.

아래 명령어로 설치해 주세요:
  uv pip install reportlab matplotlib pandas
```

### SALES-REPORT.md가 없는 경우

```
⚠️ SALES-REPORT.md 파일이 발견되지 않았습니다.

먼저 파이프라인 리포트를 생성해 주세요:
  /sales report

리포트 생성 후 다시 PDF 변환을 실행하시면 됩니다.
```

---

## 주의사항

- PDF 생성은 `generate_pdf_report.py` 스크립트에 의존합니다. 스크립트가 없으면 PDF를 생성할 수 없습니다.
- 한국어 폰트가 시스템에 설치되어 있어야 한글이 정상적으로 표시됩니다. Windows에서는 맑은고딕(Malgun Gothic)이 기본 제공됩니다.
- 대용량 리포트(프로스펙트 50개 이상)의 경우 생성에 시간이 소요될 수 있습니다.
- 생성된 PDF는 인쇄 최적화(A4 사이즈)가 적용되어 있습니다.
