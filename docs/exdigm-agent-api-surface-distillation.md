# Exdigm Agent API Surface Distillation

Exdigm Agent API의 목표는 웹 화면 버튼을 그대로 복제하는 것이 아니라 Hermes Agent가 업무 목적을 달성할 수 있는 작은 capability surface를 제공하는 것이다.

검색 앵커: Exdigm Agent API distillation, Hermes public surface, public lookup, standalone tool, workflow capability, internal route, route reduction.

## Problem

현재 `/agent/` API는 웹 화면과 버튼을 기계적으로 옮긴 route가 많다. 전체 catalog에는 164개 route가 있고, 이 중 상당수는 독립 업무가 아니라 큰 절차 안의 부속 step이다.

이 구조는 Agent에게 선택지를 너무 많이 준다. Agent는 화면 조작자가 아니라 업무 수행자이므로, `어떤 버튼 route를 누를지`보다 `어떤 업무 capability를 실행할지`를 선택해야 한다.

## Distillation Rule

Agent public surface는 route 기준이 아니라 업무 사용성 기준으로 나눈다.

| Class | Meaning | Agent exposure |
|---|---|---|
| `public_lookup` | 자주 쓰는 조회/탐색/context 확보 route | 직접 노출 |
| `public_standalone_tool` | 사용자가 기능명이나 결과물을 직접 요청하는 독립 도구 | 직접 노출 |
| `public_workflow_entry` | 큰 업무 흐름의 시작/주요 단계 route | workflow capability 안에서 노출 |
| `workflow_internal_step` | 단독 호출 가치가 낮은 부속 step | 직접 노출 금지 |
| `hidden_or_dangerous` | 삭제, offboard, owner-bind, 저수준 운영 route | 기본 비노출 |

핵심은 구현 route를 즉시 삭제하는 것이 아니다. 기존 route와 service는 엔진으로 재사용하되 Hermes가 고르는 선택지를 줄인다.

## Public Surface Shape

권장 public surface는 3종이다.

1. Lookup / Context capability
   - `business.readonly_search`
   - `project.lookup`
   - `candidate.lookup`
   - `client.lookup`
   - `email.lookup`
   - `team.lookup`
   - `reference.lookup`
   - `notification.lookup`
   - `news.lookup`

2. Standalone tool capability
   - `candidate.resume_document_generate`
   - `application.recommendation_resume_generate`
   - `project.matching_results`
   - `project.posting_generate`
   - `project.posting_download`
   - `project.submission_download`
   - `submission.draft_convert`
   - `project.resume_status`

3. Workflow capability
   - `project.create_or_update`
   - `project.candidate_discovery`
   - `project.resume_upload_extract_link`
   - `project.application_pipeline`
   - `project.stage_workflow`
   - `project.submission_workflow`
   - `project.interview_workflow`
   - `project.meeting_recording`
   - `project.next_actions`
   - `candidate.create_or_review`
   - `client.create_or_update`
   - `email.send`

## Standalone Tool Rule

큰 workflow에 속해 있어도 사용자가 자주 독립적으로 요청하고 결과물이 명확하면 standalone tool로 남긴다.

예:

- 후보자 이력서 생성
- Application 추천 이력서 생성
- 프로젝트 매칭 결과 조회
- 채용공고 생성/다운로드
- 제출용 이력서 다운로드
- 제출용 이력서 변환
- 프로젝트 이력서 처리 상태 조회

이 route들은 workflow 내부 step으로 숨기면 오히려 Agent 사용성이 나빠진다.

## Lookup Rule

범용 조회는 별도 카테고리로 유지한다. Agent가 업무를 실행하기 전에 대상 id, 상태, 연결 관계를 확인해야 하기 때문이다.

예:

- `agent_business_search`
- `agent_projects`, `agent_project_detail`
- `agent_candidate_search`, `agent_candidate_natural_search`, `agent_candidate_detail`
- `agent_clients`, `agent_client_search`, `agent_client_detail`
- `agent_team_members`
- `agent_reference_list`

조회 route는 write route보다 더 자유롭게 노출할 수 있지만, 개인정보나 권한 범위는 기존 Agent auth/scope/audit 경로를 반드시 통과한다.

## Workflow Rule

개별 route가 하나의 화면 버튼에 가깝다면 public route로 독립시키지 않는다. 대신 상위 workflow capability 안에서 sequence로 설명한다.

예:

- `project.resume_upload_extract_link`
  - upload
  - process
  - status
  - link/retry/discard

- `project.submission_workflow`
  - submissions 조회
  - draft generate
  - consultation/review/finalize
  - convert/download/submit

- `project.application_pipeline`
  - detail
  - drop/restore/return/hire/cancel
  - stage skip/revert

## Implementation Direction

다음 Xdime 코드 반영 순서:

1. `manifests/exdigm-agent-api-surface.json` 기준으로 현재 route를 검증한다.
2. `accounts/services/hermes_provisioning.py::_agent_api_menu_dict()`를 public surface 중심으로 줄인다.
3. `accounts/agent_capabilities/registry.yaml`에 standalone tool과 workflow capability의 use/do-not-use/required context를 보강한다.
4. workflow 내부 route는 catalog에는 남길 수 있지만 menu first-choice에서는 제거한다.
5. `tests/test_agent_menu_workflow_contract.py`에 public surface contract를 추가한다.
6. GBrain `reference/exdigm-agent-api-capability-catalog`와 이 문서를 함께 갱신한다.

## Validation

현재 route 분류 검증:

```bash
python3 scripts/validate-exdigm-agent-api-surface.py /home/chaconne/exdigm
```

검증이 실패하면 Xdime catalog route가 추가/삭제되었거나 distillation manifest가 stale해진 것이다.
