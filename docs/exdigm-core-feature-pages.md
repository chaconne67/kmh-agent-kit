# Exdigm Core Feature Pages

이 문서는 첫 번째 상세 GBrain page 묶음이다. 목적은 라우터보다 한 단계 깊게, 기능별로 기존 실행 경로와 재사용 기준을 알려주는 것이다.

검색 앵커: Exdigm core feature pages, 데이터 추출, 파일 업로드, JD Processor, Hermes Agent API, 기능별 상세 지식.

## Distillation Standard

이 문서는 raw code_map의 전체 파일 목록이 아니다. 각 기능마다 최대한 다음만 남긴다.

- 첫 entrypoint
- 업무 상태를 바꾸는 domain service
- Agent/API/worker 연결점
- 대표 테스트
- 새 코드를 만들기 전에 지켜야 할 reuse rule

Template, migration, admin, helper 전체 목록은 실제 문제에서 필요해질 때 code_map으로 다시 조회한다.

## Hermes Agent API

GBrain page: `project/exdigm-hermes-agents`, `reference/exdigm-agent-api-capability-catalog`, `reference/exdigm-hermes-agent-usage-guide`

Code map:

```bash
uv run python -m tools.code_map.impact --topic "헤르메스 에이전트 API"
```

First files:

- `accounts/urls_agent.py`
- `accounts/agent_api/router.py`
- `accounts/agent_capabilities/registry.yaml`
- `accounts/agent_capabilities/coverage.yaml`
- `accounts/agent_prompts/`

Rules:

- Hermes가 자연어로 route를 고르고 서버는 지정된 route만 인증·권한·감사 후 실행한다.
- `exdigm_request` fallback을 되살리지 않는다.
- 삭제 route는 Hermes 메뉴 workflow에 노출하지 않는다.
- API가 부족하면 우회 코드 대신 capability catalog를 확장한다.

Tests:

- `tests/test_agent_api_read.py`
- `tests/test_agent_api_business_search.py`
- `tests/test_agent_menu_workflow_contract.py`
- `tests/test_agent_router_phase2_tool_dispatch.py`
- `tests/test_agent_api_no_delete.py`

## Data Extraction

GBrain page: `project/exdigm-extraction-pipeline`

Code map:

```bash
uv run python -m tools.code_map.impact --topic "데이터 추출"
```

First files:

- `data_extraction/management/commands/update_candidates.py`
- `data_extraction/services/pipeline.py`
- `data_extraction/services/data_decision_policy.py`
- `data_extraction/services/extraction/`
- `data_extraction/services/save.py`

Rules:

- 수동 업로드, Mailplug/이메일, Drive 변경분은 같은 후보자 매칭 규칙을 따른다.
- 이메일/전화번호로 동일인을 판정하고 이름만으로 후보자를 병합하지 않는다.
- 추출 품질 판단은 단순 길이 기준이 아니라 `is_resume_text_sufficient`와 관련 routing을 따른다.
- 저장 테스트는 내부 helper가 아니라 최종 DB 상태, record 생성/미생성, 재시도 가능 상태를 본다.

## File Upload

GBrain page: `project/exdigm-extraction-pipeline`

Code map:

```bash
uv run python -m tools.code_map.impact --topic "파일 업로드"
```

First files:

- `data_extraction/services/upload_resume_file_to_drive.py`
- `data_extraction/services/drive_upload_targets.py`
- `data_extraction/services/save_resume_file_metadata.py`
- `data_extraction/services/resume_file_upload_tools.py`

Rules:

- Drive 업로드 대상은 등록된 intake target을 사용한다.
- 업로드 후 parents가 target folder와 정확히 일치하는지 검증한다.
- 위치 확인 실패 시 성공 기록을 남기지 않는다.
- 같은 업로드를 web, Mailplug, worker가 서로 다른 저장 경로로 처리하지 않는다.

## JD Processor

GBrain page: `project/exdigm-extraction-pipeline`

Code map:

```bash
uv run python -m tools.code_map.impact --topic "JD Processor"
```

First files:

- `projects/services/jd_processor.py`
- `projects/services/project_creation_requests.py`
- `projects/management/commands/process_job_descriptions.py`
- `accounts/agent_api/project.py`

Rules:

- Mail checker는 JobDescription을 직접 만들지 않는다.
- JobDescription 생성과 여러 JD 분리는 JD processor가 맡는다.
- JD processor는 `ProjectCreationRequest`와 알림 경로를 만든다.
- Telegram 대화형 생성은 Hermes가 `project.jd_creation_request` capability로 진행한다.

## Project Workflow

GBrain page: `project/exdigm-feature-map`

Code map:

```bash
uv run python -m tools.code_map.impact --topic "프로젝트"
uv run python -m tools.code_map.impact --topic "프로젝트 진행 단계"
```

First files:

- `projects/views/`
- `projects/services/application_lifecycle.py`
- `projects/services/action_lifecycle.py`
- `projects/services/searching.py`
- `projects/templates/projects/`

Rules:

- 프로젝트 맥락의 후보자는 Candidate, 예비 후보, 진행 후보 Application을 구분한다.
- 단계 변경과 액션 변경은 lifecycle service를 우회하지 않는다.
- 화면 변경은 template/partial 실제 사용 경로와 브라우저 검증을 확인한다.
