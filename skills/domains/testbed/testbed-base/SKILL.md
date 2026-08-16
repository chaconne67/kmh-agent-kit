---
name: testbed-base
description: Use for FundKeeper work involving the KOSCOM RA second testbed, its fund codes, TestBed2 balance/report data, or testbed portal uploads.
---

# FundKeeper 코스콤 RA 테스트베드

코스콤 RA 테스트베드 2차 자문일임 작업의 공통 도메인과 포털 업로드 계약이다.

## 전제 조건

- 포털: `https://www.ratestbed.kr:7443`
- 인증 환경변수: `TESTBED_ID`, `TESTBED_PW`
- 작업 서류: 사용자가 지정한 실제 파일 경로
- 공통 업로드 도구: 이 스킬 폴더의 `portal_upload.py`
- 실행 기반: 설치된 `uv`와 Google Chrome

중앙 서버에는 인증 환경변수와 Windows Google Drive 서류 경로가 기본 제공되지 않는다. 값 존재 여부와 작업 파일 경로를 확인할 수 없으면 업로드나 서류 변경을 시작하지 않는다. 비밀값은 출력하지 않는다.

## 펀드 코드

| 유형 | 1(350만) | 2(500만) | 3(650만) |
|---|---|---|---|
| 안정추구 | R26233 | R26234 | R26235 |
| 위험중립 | R26236 | R26237 | R26238 |
| 적극투자 | R26239 | R26240 | R26241 |

이 값은 국내 ETF 2차 포털의 고정 식별자다. 다른 테스트베드나 전략에 재사용하지 않는다.

## TestBed2 계약

```python
tb2 = TestBed2(schedule_id=N)
tb2.모델포트폴리오(pk_list)
tb2.잔고내역불러오기(pk_list)
tb2.거래내역기반잔고추정(pk_list, target_date=...)
```

- `모델포트폴리오`는 출력만 하고 `None`을 반환하므로 결과가 필요하면 stdout을 캡처한다.
- `잔고내역불러오기`는 선행 `TestBedBalance`가 없으면 `None`을 반환한다.
- 거래 실행일은 `rday` 전후 10일의 `TradeHistory`에서 확인한 마지막 거래일이다.
- 모델포트폴리오 생성일과 거래 실행일을 같은 날짜로 가정하지 않는다.
- 잔고 저장·보고서 갱신·포털 제출은 데이터나 외부 시스템을 바꾸므로 주인님의 명시 승인 뒤 실행한다.

## 포털 업로드

먼저 `--dry-run`으로 로그인·폼·파일을 검증한다. dry-run은 기존 첨부파일 삭제와 최종 제출을 건너뛴다. 실제 제출은 결과와 대상 URL·파일·제목·이력 문구를 확인한 뒤 실행한다.

```bash
uv run --with playwright /absolute/path/to/testbed-base/portal_upload.py \
  --url "https://www.ratestbed.kr:7443/cop/bbs/forUpdate.do?nttId=XXX&algrthSn=YYY" \
  --file "/absolute/path/to/report.pdf" \
  --title "제목_YYYYMMDD" \
  --content-append "변경 이력" \
  --dry-run
```

- 성공·실패·dry-run 결과는 stdout의 JSON으로 판정한다.
- 실패하면 exit code와 단계별 스크린샷을 확인한다.
- 스크립트 실패 원인을 확인하기 전에 수동 브라우저 제출로 우회하지 않는다.
