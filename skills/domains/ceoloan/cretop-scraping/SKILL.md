---
name: cretop-scraping
description: CRETOP(크레탑) 브라우저·로그인 상태 확인, 기업 상세 조회·수집, 배치 실행·재개, 수집 오류 진단에 사용한다.
---

# CRETOP 스크래핑

## 역할

기존 RNDLOG 래퍼를 통해 CRETOP Windows 브라우저를 조사하고 수집한다. Windows는 화면 조작과 증거 생성을 맡고, 중앙 래퍼는 결과 검증과 `company` 스키마 저장을 맡는다.

별도 브라우저 runner나 임시 수집 스크립트를 만들지 않는다. 현재 래퍼와 Windows agent가 실행 경로의 정본이므로, 다른 경로를 만들면 로그인 세션·품질검사·저장 재개 계약이 갈라진다.

검증된 CRETOP 사실을 대출 산정이나 보고서 생성에 넘길 수 있지만, 산정·보고서 생성 자체는 별도 요청과 해당 실행 경로에서 처리한다.

## 정본 확인

작업 전에 다음 순서로 현재 계약을 확인한다.

1. 현재 프로젝트 지침과 `~/.gbrain-agent.md`를 읽고 카드가 지정한 선행 GBrain 페이지를 확인한다.
2. GBrain의 `project/cretop-windows-runtime`에서 현재 접속 경로·로그인 상태·운영 위험을 확인한다.
3. 현재 RNDLOG 저장소의 Git 상태를 확인하고 기존 변경을 보존한다.
4. RNDLOG의 `scripts/cretop_detail_collection.py`, `scripts/cretop_agent.py`, `docs/cretop/cretop_local_primary_runbook.md`, `docs/cretop/final_collection_procedure.md`에서 현재 명령과 화면 계약을 확인한다.

코드와 GBrain이 다르면 현재 코드와 직접 확인한 서버 상태를 기준으로 삼고, 검증 후 GBrain을 갱신한다. 서버 주소·화면 좌표·로그인 marker·파일 hash를 이 스킬에 복사하지 않는다. 변할 수 있는 값은 정본에서 매번 다시 확인한다.

## 작업 단계

브라우저 관련 작업 전에 현재 단계를 선언한다.

| 단계 | 목적 | 허용 경로 |
|---|---|---|
| 조사 | 브라우저·탭·로그인 상태와 장애 증거 확인 | 공식 래퍼의 `remote-inspect-browser`; 호스트 상태만 승인된 읽기 전용 SSH |
| 실행 | 기업 조회, preflight, 배치 수집, 결과 회수와 저장 | 공식 래퍼의 해당 명령 |
| 통합 | 확인한 화면 변경을 영구 자동화에 반영 | 요청받은 경우에만 기존 래퍼 또는 Windows agent의 담당 단계 수정 |

조사 결과만 필요한 요청에서 preflight·검색·DB 저장으로 넘어가지 않는다. 실행 권한은 사용자의 현재 요청에서 확인하고, 외부 화면 조작이나 DB 쓰기가 요청 범위 밖이면 멈춘다.

## 실행 전 점검

- RNDLOG 저장소의 프로젝트 Python 경로에서 래퍼 `--help`가 실행되는지 확인한다. 시스템 Python으로 대체하지 않는다.
- 현재 접속 경로와 Administrator console의 기존 Chrome 소유권을 확인한다.
- 상태가 불명확하면 수집보다 `remote-inspect-browser`를 먼저 실행한다.
- 단일 기업 조회에는 숫자 10자리 사업자등록번호를 사용한다. 회사명은 확인된 값만 넘기고 추정하지 않는다.
- 배치에는 사용자가 승인한 수집 범위를 `--limit`으로 명시한다. 쓰기 효과가 있으므로 CLI 기본값에 맡기지 않는다.
- 시작 명령마다 추적 가능한 고유 `--run-id`를 정하고, 상태 확인·회수·재개에 같은 값을 사용한다.
- 필요한 DB·Telegram 환경값은 이름과 존재 여부만 확인한다. 비밀값·쿠키·세션·비밀번호를 출력하거나 증거에 기록하지 않는다.

모든 명령은 현재 RNDLOG 루트에서 프로젝트의 공식 실행기인 `uv run python`으로 실행한다.

## 조사

다음 명령으로 기존 Chrome을 조작하지 않는 진단 증거를 만든다.

```bash
uv run python scripts/cretop_detail_collection.py \
  remote-inspect-browser \
  --run-id <run-id>
```

요약 JSON과 스크린샷에서 console 세션, Chrome 창, CRETOP 탭, 로그인·팝업 상태를 확인한다. 호스트 수준 진단이 추가로 필요하면 승인된 SSH 또는 래퍼의 제한된 원격 명령을 읽기 전용으로 사용하고, Chrome 프로세스나 창을 제어하지 않는다.

## Preflight

조사 결과가 기존 로그인 세션의 공식 복구·연장 경로를 지원하고 사용자가 화면 조작을 요청했을 때만 실행한다.

```bash
uv run python scripts/cretop_detail_collection.py \
  remote-preflight \
  --run-id <run-id>

uv run python scripts/cretop_detail_collection.py \
  remote-batch-status \
  --run-id <run-id>

uv run python scripts/cretop_detail_collection.py \
  remote-result-fetch \
  --run-id <run-id>
```

완전 로그아웃처럼 비밀번호 입력이 필요한 상태에서는 preflight를 시작하지 않는다. 사람이 기존 Chrome 프로필의 로그인을 복구한 뒤 새 `run-id`로 다시 조사한다.

## 단일 기업 조회

사용자가 특정 기업의 화면 조회를 요청했을 때만 실행한다.

```bash
uv run python scripts/cretop_detail_collection.py \
  remote-search-detail \
  --business-number <10-digit-business-number> \
  --run-id <run-id>

uv run python scripts/cretop_detail_collection.py \
  remote-batch-status \
  --run-id <run-id>

uv run python scripts/cretop_detail_collection.py \
  remote-result-fetch \
  --run-id <run-id>
```

확인된 회사명이 있을 때만 시작 명령에 `--company-name <verified-company-name>`을 추가한다. `remote-search-detail`은 원격 작업 시작이고 `remote-result-fetch`는 원시 결과·증거 회수다. 원시 결과는 중앙 래퍼의 8개 화면 품질검사를 통과한 저장 결과가 아니므로 검증된 기업 사실이나 중앙 DB 저장 성공으로 보고하지 않는다. 검증·저장이 목적이면 배치 경로를 사용한다. 결과 파일이 생기고 작업이 더 이상 실행 중이 아닐 때만 회수한다.

## 배치 수집과 저장

사용자가 CRETOP 결과의 중앙 저장까지 요청한 경우 다음 단일 경로를 사용한다.

```bash
uv run python scripts/cretop_detail_collection.py \
  batch-script-only-collect \
  --limit <approved-limit> \
  --run-id <run-id>

uv run python scripts/cretop_detail_collection.py \
  remote-batch-status \
  --run-id <run-id>

uv run python scripts/cretop_detail_collection.py \
  remote-batch-fetch \
  --run-id <run-id>
```

상태 확인은 결과 파일이 생기고 작업이 더 이상 실행 중이 아닐 때 끝낸다. 작업이 실패했거나 결과 없이 끝났으면 증거를 보고하고 멈춘다. 같은 전제로 작업 시작 명령을 반복하지 않는다.

`remote-batch-status`는 결과 파일이 있는 완료 작업의 예약 작업을 정리할 수 있지만 원격 결과 파일은 보존한다. 이를 중앙 저장 성공으로 해석하지 않는다. `remote-batch-fetch`가 증거 회수, 8개 화면 품질검사와 중앙 저장을 소유한다. 중앙 저장이 실패하면 원격 결과와 같은 `run-id`를 보존하고 `remote-batch-fetch`로 재개한다. 새 배치를 시작하거나 수동으로 DB를 보정하지 않는다.

## 품질과 데이터 계약

- 승인된 텍스트 화면은 `briefing`, `general_overview`, `status_business`, `status_tech_cert`, `finance_statement`, `finance_diagnosis`, `finance_analysis`, `credit_rating`의 8개다.
- 각 화면은 비어 있지 않아야 하고 로그인·팝업 문구가 없어야 한다.
- 각 화면의 기업명 또는 사업자등록번호와 머리말의 사업자등록번호가 대상 기업과 일치해야 한다.
- 8개 화면 전체가 같은 복사문이면 품질 실패로 처리한다.
- 품질 실패 항목은 저장하지 않고 `deferred_items`와 증거로 남긴다.
- 기업 사실은 중앙 `company` 스키마에만 저장한다. CEO Loan 모델에 복사하거나 Windows에서 DB에 직접 쓰지 않는다.
- 상태 확인이나 회수 명령이 수행한 예약 작업 정리와 중앙 DB 저장 성공을 구분해 보고한다.

## 브라우저 안전 경계

- 기존 사용자 Chrome·프로필·창·탭·프로세스를 닫거나 종료하지 않는다.
- 새 Chrome이나 새 탭을 만들거나 인증 프로필을 바꾸지 않는다.
- 주소창 직접 이동, JavaScript·DevTools·내부 router, 임시 Playwright·Selenium으로 화면 경로를 우회하지 않는다. 현재 사이트는 기존 로그인 탭과 검증된 화면 상태 전이에 의존하므로 Windows agent의 가시적 화면 경로를 사용한다.
- 화면이 바뀌어 공식 경로가 실패하면 증거를 보존하고 통합 단계로 돌아간다. 임시 runner로 결과를 만들지 않는다.
- 완전 로그아웃·비밀번호·OTP·CAPTCHA 등 승인된 처리 경로가 없는 인증 요구에서는 멈추고 사람이 기존 프로필의 로그인을 복구하도록 보고한다.
- 유료 서비스 확인, 판정 불가, 본문 복사 실패, 복구 marker 실패, 같은 배치의 반복 페이지 만료에서는 화면을 더 진행하지 않고 결과와 스크린샷을 보존한다.
- 과거 결과·스크린샷·예약 작업 정리는 데이터 삭제이므로 별도 승인을 받는다.

## 완료 보고

다음 항목을 구분해 보고한다.

- 실행 단계와 `run-id`
- 요청받은 기업 또는 배치 범위
- 확인한 로그인·브라우저 상태
- 실행한 공식 명령과 증거 경로
- 단일 조회 결과 또는 배치의 저장·보류 건수
- 원격 작업 정리 여부
- 인증·품질·저장 장애와 안전하게 보존한 재개 지점

직접 확인하지 않은 화면, 저장, 작업 정리를 성공으로 보고하지 않는다.
