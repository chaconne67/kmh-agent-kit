# Exdigm Smart Targeting Index

Exdigm 작업에서 가장 중요한 GBrain 지식은 에이전트가 새 코드를 만들기 전에 기존 실행 경로를 정확히 찾게 하는 것이다. 이 문서는 질문을 받았을 때 먼저 볼 code_map topic, GBrain page, 재사용 경로를 정하는 라우터다.

검색 앵커: Exdigm smart targeting, 정밀 타겟팅, 코드 재사용, 기능 라우팅, Hermes Agent API, Agent API route, code_map, 기존 코드 찾기.

증상 앵커: Hermes 메뉴 API 못 고름, Agent API가 너무 좁음, API 우회 코드, 이력서 업로드 Drive 위치 문제, 첨부파일 처리 문제, JD 메일 프로젝트 생성 안 됨, Mailplug JD 처리, 후보자 중복 생성, 최신 이력서 반영, 알림 다운로드 링크, 배포 worker 문제.

## Core Rule

Exdigm 작업 전에는 GBrain 검색만으로 끝내지 않는다. 반드시 해당 기능의 `tools/code_map` topic 또는 파일 impact를 같이 본다.

```bash
uv run python -m tools.code_map.impact --topic "<topic label or alias>"
uv run python -m tools.code_map.impact --file <path>
```

새 route, template, management command, Agent API surface, worker script, 핵심 테스트가 생기면 `tools/code_map/semantic_topics.toml`도 갱신한다.

## Distillation Rule

`tools/code_map` 결과를 그대로 GBrain 지식으로 복사하지 않는다. code_map은 raw map이고, GBrain smart targeting index는 distilled map이어야 한다.

GBrain에 남길 것:

- 실제 요청이 들어왔을 때 가장 먼저 볼 entrypoint
- 업무 상태를 바꾸는 domain service
- Agent API route/capability registry
- 대표 테스트와 검증 명령
- 새 경로를 만들면 안 되는 reuse rule

GBrain에 남기지 않을 것:

- topic에 걸린 모든 template/partial/static 파일 목록
- migrations, admin, boilerplate
- 단순 import barrel 또는 `__init__.py`
- 같은 의미의 helper 전체 나열
- 지금 코드로 바로 조회 가능한 장황한 파일 dump

판단 기준: 이 항목이 없으면 에이전트가 잘못된 파일을 먼저 보거나 새 병렬 경로를 만들 가능성이 있는가? 없으면 GBrain index에서 뺀다.

## Agentic API Balance

Hermes Agent는 Exdigm 업무만 실행해야 한다. 그러나 API가 너무 좁으면 에이전트의 판단 능력이 사라지고, API 밖에서 프로그램 방식으로 우회하면 경로가 여러 개 생긴다.

올바른 구조는 다음과 같다.

- Agent는 Exdigm 업무 catalog 안에서 자유롭게 판단한다.
- 서버는 인증, 권한, 감사, 삭제 금지, 위험 작업 제한을 강제한다.
- Agent API는 목줄이 아니라 업무 capability boundary다.
- Agent가 어떤 route를 골라야 하는지는 GBrain smart targeting 지식과 Agent API catalog가 알려준다.
- route가 부족하면 임시 우회 코드를 만들지 말고 capability를 설계해 Agent API에 추가한다.

상세 기준은 `reference/exdigm-agent-api-capability-catalog`와 `reference/exdigm-hermes-agent-usage-guide`를 따른다.

## Work Intake Router

| User intent / symptom | First code_map topic | First GBrain target | First files to inspect |
|---|---|---|---|
| Hermes가 메뉴/API를 못 고른다 | `헤르메스 에이전트 API` | `project/exdigm-hermes-agents`, `reference/exdigm-smart-targeting-index` | `accounts/agent_api/router.py`, `accounts/agent_capabilities/registry.yaml`, `accounts/agent_prompts/` |
| Telegram bot onboarding/container 문제 | `Telegram 온보딩` | `project/exdigm-hermes-agents` | `accounts/services/hermes_provisioning.py`, `accounts/agent_api/account.py`, Docker provisioning files |
| Agent API key, scope, permission | `권한·팀` | `project/exdigm-operating-context` | `accounts/services/agent_api_keys.py`, `accounts/agent_api/_common.py`, `accounts/agent_api/team.py` |
| 이력서/JD/메일 추출 품질 | `데이터 추출` | `project/exdigm-extraction-pipeline` | `data_extraction/services/pipeline.py`, `data_extraction/services/extraction/`, `data_extraction/services/data_decision_policy.py` |
| Mailplug JD 메일이 프로젝트 생성으로 이어지지 않음 | `JD Processor` | `project/exdigm-extraction-pipeline` | `projects/services/jd_processor.py`, `projects/services/project_creation_requests.py`, `projects/management/commands/process_job_descriptions.py` |
| 파일 업로드/Drive 위치/첨부 처리 | `파일 업로드` | `project/exdigm-extraction-pipeline` | `data_extraction/services/upload_resume_file_to_drive.py`, `data_extraction/services/drive_upload_targets.py`, `data_extraction/services/save_resume_file_metadata.py` |
| 후보자 생성/중복/최신 이력서 반영 | `후보자 등록`, `이력서 최신 버전` | `project/exdigm-data-models` | `candidates/`, `data_extraction/services/save.py`, `projects/services/resume/` |
| 프로젝트 화면/후보자 진행 단계 | `프로젝트`, `프로젝트 진행 단계` | `project/exdigm-feature-map` | `projects/views/`, `projects/services/application_lifecycle.py`, `projects/templates/projects/` |
| 후보자 검색/추천/JD 매칭 | `프로젝트 후보자 발굴`, `후보자 검색·임베딩` | `project/exdigm-feature-map` | `projects/services/searching.py`, candidate search/embedding services |
| 제출용/추천 이력서 생성 | `이력서 생성` | `project/exdigm-feature-map` | `projects/services/recommendation_*`, `projects/services/resume_templates/` |
| 알림벨/Telegram 알림/download link | `알림` | `project/exdigm-feature-map` | `projects/services/notification.py`, `projects/views/notifications.py`, `projects/templates/projects/partials/notification_bell.html` |
| 배포, Docker, worker, cleanup | `배포·운영` | `project/exdigm-deploy-workflow` | `deploy/`, `scripts/`, Docker stack files |
| 이메일 수집/발송/메일 워크벤치 | `이메일 워크벤치` | `project/exdigm-extraction-pipeline` | `data_extraction/services/mailplug.py`, `projects/services/email/`, email workbench API files |

## Reuse Before Creation

새 코드를 만들기 전에 다음을 먼저 찾는다.

- 같은 업무를 처리하는 service 함수
- Agent API route 또는 capability registry 항목
- management command와 worker script
- 기존 model method/property/constraint
- 이미 있는 template partial 또는 form
- 기존 테스트가 검증하는 business-observable result

찾지 못했다면 바로 새로 만들지 말고, code_map topic이 빠졌는지 확인한다. 기능이 존재하는데 topic이 없으면 `semantic_topics.toml`을 먼저 보강한다.

## Failure Pattern To Avoid

나쁜 흐름:

```text
API가 부족하다
→ 에이전트가 우회 프로그램 코드를 만든다
→ 같은 업무 실행 경로가 두 개가 된다
→ 한쪽을 고쳐도 실제 사용 경로가 안 바뀐다
→ 실패 지점과 검증 지점이 분리된다
```

좋은 흐름:

```text
API가 부족하다
→ 필요한 Exdigm 업무 capability를 정의한다
→ 기존 service/permission/audit 경로를 재사용한다
→ Agent API route 또는 registry를 확장한다
→ code_map과 GBrain smart targeting index를 갱신한다
```

## Completion Check

Exdigm 코드 작업 완료 전 질문:

- 내가 수정한 기능의 code_map topic을 확인했는가?
- 기존 실행 경로를 재사용했는가?
- 새 병렬 경로를 만들지 않았는가?
- Agent API/capability를 바꿨다면 registry, prompt, tests, GBrain index를 같이 갱신했는가?
- 검증이 실제 업무 결과를 확인했는가?
