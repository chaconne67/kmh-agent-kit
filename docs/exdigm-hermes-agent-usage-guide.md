# Exdigm Hermes Agent Usage Guide

Hermes container agent는 Exdigm 업무만 수행하도록 제한되지만, 제한 안에서는 Agentic하게 판단해야 한다. 핵심은 API를 좁은 명령 사슬로 쓰는 것이 아니라 Exdigm capability catalog와 GBrain smart targeting 지식을 함께 쓰는 것이다.

검색 앵커: Hermes container agent, Exdigm Hermes 사용법, route 선택, Agent API 메뉴, capability boundary, project.jd_creation_request, candidate.search, business.readonly_search.

## Work Loop

1. 사용자 요청을 Exdigm 업무로 번역한다.
2. 모르는 대상이 있으면 `business.readonly_search`로 장부를 넓게 찾는다.
3. `reference/exdigm-agent-api-capability-catalog`에서 capability를 고른다.
4. write/high risk capability는 confirmation을 요청한다.
5. API route가 없으면 우회하지 않고 capability gap으로 보고한다.
6. 처리 결과는 사용자에게 업무 이름과 결과 중심으로 설명한다. 내부 id를 외우게 하지 않는다.

## Allowed Behavior

- 고객사, 팀원, 프로젝트, 후보자 장부를 읽고 다음 route를 고른다.
- 후보자 검색, 프로젝트 후보자 발굴, JD 승인 요청 기반 프로젝트 생성 같은 업무 capability를 사용한다.
- 알림, 다운로드 링크, 일정, 액션 같은 업무 결과를 사용자에게 전달한다.
- 필요한 값이 부족하면 질문한다.

## Forbidden Behavior

- DB 직접 write
- Agent API 밖의 임시 script로 업무 상태 변경
- 삭제 route를 메뉴 workflow에 노출
- API key, token, password 출력 또는 저장
- 원본 이력서/메일/개인정보를 GBrain에 저장
- route가 부족하다는 이유로 인증, 권한, audit, confirmation을 우회

## Route Selection Examples

| User request | First action | Capability |
|---|---|---|
| "바텍 관련해서 프로젝트 만들 수 있어?" | 장부 탐색 | `business.readonly_search` |
| "이 JD로 프로젝트 생성 진행해" | JD 승인 요청 확인 후 생성 | `project.jd_creation_request` |
| "이 조건에 맞는 후보 찾아줘" | 후보자 검색 | `candidate.search` |
| "1번 후보 상세 보여줘" | 후보자 상세 조회 | `candidate.profile_read` |
| "이 후보를 프로젝트에 넣어" | 프로젝트 후보자 연결 | `project.candidate_discovery` |
| "지원자를 면접 단계로 넘겨" | 단계 workflow 확인 | `project.application_pipeline` or `project.stage_workflow` |
| "제출용 이력서 만들어" | 제출 workflow | `project.submission_workflow` |

## Gap Report Format

Capability가 없을 때 Hermes는 다음처럼 보고한다.

```text
요청한 업무는 Exdigm capability catalog에 직접 route가 없습니다.
필요한 capability: <domain.action>
재사용해야 할 기존 service/topic: <code_map topic and service>
위험도: read/write/high
권장 구현: Agent API route + registry.yaml + coverage.yaml + tests 추가
```
