# Exdigm Agent API Capability Catalog

Agent API는 route 목록이 아니라 Exdigm 업무 capability catalog다. Hermes Agent는 이 catalog 안에서 자유롭게 판단하고, 서버는 인증·권한·감사·위험 작업 제한을 강제한다.

검색 앵커: Agent API capability catalog, Hermes route 선택, Exdigm 업무 catalog, capability boundary, candidate.search, project.create_from_jd, resume.upload, notification.deliver, application.advance_stage.

## Authoritative Sources

- Capability definitions: `accounts/agent_capabilities/registry.yaml`
- Route coverage: `accounts/agent_capabilities/coverage.yaml`
- API router: `accounts/agent_api/router.py`
- URL entrypoint: `accounts/urls_agent.py`
- Prompt surface: `accounts/agent_prompts/`

## Selection Rule

Agent가 route를 고르는 순서:

1. 사용자 요청을 Exdigm 업무 capability로 번역한다.
2. 필요한 장부를 모르면 `business.readonly_search`로 read-only 탐색한다.
3. 읽기 capability와 쓰기 capability를 분리한다.
4. write/high risk capability는 confirmation 정책을 확인한다.
5. 삭제나 파괴적 route는 메뉴 workflow에 노출하지 않는다.
6. route가 없으면 우회 코드를 만들지 말고 capability를 설계한다.

## Core Capabilities

| Capability | Use when | Risk | First code_map topic |
|---|---|---|---|
| `business.readonly_search` | 고객사/팀원/프로젝트/후보자 중 어느 장부를 먼저 볼지 모를 때 | low/read | `헤르메스 에이전트 API` |
| `candidate.search` | 조건이나 자연어로 후보자를 찾을 때 | low/read | `후보자 검색·임베딩` |
| `candidate.profile_read` | 특정 후보자 상세/연락처/경력/학력을 볼 때 | medium/read | `후보자 워크스페이스` |
| `candidate.profile_write` | 새 후보자 기본 정보를 등록할 때 | medium/write/confirm | `후보자 등록` |
| `candidate.review_ingestion` | 추출 후보자 검토, 확정, 반려 | medium/read_write/confirm | `후보자 등록`, `데이터 추출` |
| `candidate.resume_source_link` | 후보자 원본 이력서 링크 조회 | medium/read | `이력서 최신 버전` |
| `client.management` | 고객사/계약 조회·생성·수정 | high/read_write | `고객사·계약` |
| `project.management` | 프로젝트 생성·수정·종료 기본 관리 | high/write/confirm | `프로젝트` |
| `project.jd_creation_request` | JD 승인 요청 기반 프로젝트 생성 | high/write/confirm | `JD Processor` |
| `project.candidate_discovery` | 프로젝트/JD 기반 후보자 발굴 | medium/read_write | `프로젝트 후보자 발굴` |
| `project.application_pipeline` | 지원자 단계 이동, 탈락, 복구, 채용 | high/write/confirm | `프로젝트 진행 단계` |
| `project.stage_workflow` | 접촉, 사전 미팅, 면접, 추천 준비 단계 업무 | medium/read_write | `프로젝트 진행 단계` |
| `project.resume_workflow` | 프로젝트 이력서 업로드/배정/재처리 | high/read_write | `이력서 생성`, `파일 업로드` |
| `project.submission_workflow` | 제출용 이력서 생성·제출·피드백 | high/write/confirm | `이력서 생성` |
| `project.notifications` | 프로젝트 알림 조회·처리 | low/read_write | `알림` |
| `account.email_workbench` | 회사 이메일 읽기/발송 | medium/read_write | `이메일 워크벤치` |
| `team.access_management` | 팀원과 가입 승인 관리 | high/read_write | `권한·팀` |

## Capability Gap Rule

요청을 처리할 route가 없을 때:

1. `reference/exdigm-smart-targeting-index`에서 기능 영역을 찾는다.
2. `tools.code_map.impact`로 기존 service와 tests를 찾는다.
3. 기존 service/permission/audit 경로를 재사용해 capability를 정의한다.
4. `registry.yaml`, `coverage.yaml`, router/prompt/tests를 함께 갱신한다.
5. GBrain smart targeting index와 이 catalog를 갱신한다.

## Anti-Pattern

금지:

- Agent가 DB를 직접 조작하는 우회 코드
- Agent API 밖에 별도 업무 실행 script를 만드는 것
- 같은 업무를 web view, worker, Agent API가 서로 다른 service로 처리하는 것
- route가 없다는 이유로 인증/권한/audit 경로를 생략하는 것

권장:

- web view, worker, Agent API가 같은 domain service를 재사용한다.
- Agent API는 입력/권한/감사/confirmation을 담당한다.
- 업무 상태 변경은 기존 lifecycle/service 경로를 통과한다.
