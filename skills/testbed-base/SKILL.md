---
name: testbed-base
description: FundKeeper 테스트베드 - 코스콤 RA 테스트베드 2차 (자문일임)
---

# FundKeeper 테스트베드 - 코스콤 RA 테스트베드 2차 (자문일임)

**관련**: `fundkeeper` (프로젝트), `fundkeeper-deploy` (배포)
**접속정보**: `C:\Users\chaconne\.env` → `TESTBED_ID`, `TESTBED_PW` (포털: https://www.ratestbed.kr:7443)
**서류 디렉토리**: `C:\Users\chaconne\Google Drive 스트리밍\내 드라이브\MOA\테스트베드2차\준비서류\`

## 펀드코드 (국내ETF 2차, 포털 고정값)
| 유형 | 1(350만) | 2(500만) | 3(650만) |
|---|---|---|---|
| 안정추구 | R26233 | R26234 | R26235 |
| 위험중립 | R26236 | R26237 | R26238 |
| 적극투자 | R26239 | R26240 | R26241 |

## TestBed2 API 함정 (코드만 봐서 모르는 것)

```python
tb2 = TestBed2(schedule_id=N)  # RebalancingSchedule PK
tb2.모델포트폴리오(pk_list)          # ⚠ print만, 반환None → stdout 캡처 필요
tb2.잔고내역불러오기(pk_list)        # ⚠ TestBedBalance 없으면 None (잔고내역저장 선행 필요)
tb2.거래내역기반잔고추정(pk_list, target_date=...)  # 잔고불러오기 대안. target_date 다르면 다른 결과
```

거래 실행일: rday 전후 10일간 TradeHistory에서 마지막 거래일 (MP생성일=rday, 실행일=마지막거래일)

## 공통 스크립트: portal_upload.py

포털 서류 업로드를 자동화하는 Playwright CLI 스크립트. `testbed-algo-report`, `testbed-rebal-report`에서 공유.

**위치**: `~/.claude/skills/testbed-base/portal_upload.py`

### 사용법
```
python ~/.claude/skills/testbed-base/portal_upload.py \
  --url "https://www.ratestbed.kr:7443/cop/bbs/forUpdate.do?nttId=XXX&algrthSn=YYY" \
  --file "/path/to/file.pdf" \
  --title "새 제목_20260313" \
  --content-append "2026-03-13 정기리밸런싱 반영" \
  [--dry-run]
```

- `--dry-run`: 최종 제출 스킵, 폼 상태 JSON 출력 (검증용)
- 출력: JSON (stdout). `{"status": "success"|"error"|"dry_run", ...}`
- 에러 시 step별 스크린샷 캡처, exit code 1
- 인증정보: `~/.env`의 `TESTBED_ID`/`TESTBED_PW` 자동 로드

### SubAgent 위임 패턴

포털 업로드는 기계적 작업이므로 SubAgent에 위임하여 메인 context를 보존한다.

**SubAgent 프롬프트 템플릿**:
```
실행: python ~/.claude/skills/testbed-base/portal_upload.py \
  --url "{forUpdate_URL}" --file "{파일경로}" \
  --title "{새_제목}" --content-append "{이력_내용}"
성공 시 JSON 결과 보고. 실패 시 에러 메시지와 스크린샷 경로 보고.
```

### 병렬 업로드
복수 서류를 동시에 업로드할 때 각각 별도 SubAgent로 파견. 각 SubAgent가 독립 브라우저를 실행하므로 충돌 없음.
```
SubAgent A → 11번 서류 PDF 업로드
SubAgent B → 21번 서류 엑셀 업로드
```

## 알고리즘설명서 (pptx)
→ `testbed-algo-report` 스킬 참조

## 리밸런싱 발생내역 (엑셀)
→ `testbed-rebal-report` 스킬 참조
