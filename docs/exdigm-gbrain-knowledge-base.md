# Exdigm GBrain Knowledge Base

Exdigm 자체는 GBrain에서 가장 먼저 구축해야 할 핵심 지식 대상이다. 목표는 매 세션마다 기능, 구조, 배포, 코드 위치, 설계 이유를 다시 설명하지 않게 하는 것이다.

## Knowledge Hierarchy

권장 GBrain page 계층:

- `project/exdigm-domain-index`: Exdigm 작업 시작점과 주요 하위 페이지 링크
- `reference/exdigm-smart-targeting-index`: 질문/증상별 code_map topic, GBrain page, 기존 재사용 경로 라우터
- `project/exdigm-overview`: 서비스 목적, 핵심 사용자, 주요 업무 흐름
- `project/exdigm-architecture`: Django 앱, worker, DB, Docker/Swarm, Hermes agent 구성
- `project/exdigm-feature-map`: 화면/menu/API/worker별 기능 목록
- `project/exdigm-data-models`: 핵심 모델, 필드 의미, 설계 rationale
- `project/exdigm-deploy-workflow`: 개발/운영 배포와 검증 순서
- `project/exdigm-hermes-agents`: Hermes agent API, container, provisioning, fleet 운영
- `project/exdigm-extraction-pipeline`: 이력서/JD/메일/Drive 추출 파이프라인
- `reference/exdigm-code-map-usage`: `tools/code_map` 사용법과 topic 관리 규칙

## Code Map Role

`tools/code_map`은 현재 코드 기준의 기능별 영향 범위 지도다. GBrain은 그 구조의 의미, 설계 이유, 운영 교훈을 저장한다. 둘 중 하나만 쓰면 안 된다.

작업 전:

```bash
uv run python -m tools.code_map.impact --topic "<기존 topic label 또는 alias>"
```

파일을 먼저 알고 있으면:

```bash
uv run python -m tools.code_map.impact --file <path>
```

작업 후 새 기능, route, template, management command, Agent API surface, 핵심 테스트가 생기면:

```bash
uv run python -m tools.code_map.inventory --root .
uv run python -m tools.code_map.validate --root .
```

필요하면 `tools/code_map/semantic_topics.toml`도 같이 갱신한다.

## Update Rule

Exdigm 코드 변경 후 완료 조건:

1. 변경 기능의 code_map topic을 확인한다.
2. 새 영향 범위가 생기면 `semantic_topics.toml`을 갱신한다.
3. 설계 이유, 운영 절차, 반복 교훈이 생기면 GBrain의 Exdigm page를 갱신한다.
4. GBrain 기억과 현재 코드가 충돌하면 현재 코드를 기준으로 GBrain을 갱신한다.
5. 최종 보고에 code_map/GBrain 갱신 여부를 포함한다.

## Storage Standard

GBrain에 저장할 내용:

- 기능의 목적과 사용 흐름
- 코드 위치와 entrypoint
- 모델/필드/status 이름의 의미와 이유
- 배포/운영/worker 순서
- 과거 버그의 근본 원인과 재발 방지 규칙
- 사용자가 반복해서 설명한 도메인 규칙

저장하지 않을 내용:

- secrets, token, password, DB URL
- 고객 개인정보, 이력서/메일 원문
- 단순 tool output dump
- 현재 코드로 즉시 확인 가능한 장황한 파일 목록
- 검증되지 않은 추측

## Current Gap

현재 code_map에는 세부 기능 topic은 많지만 `Exdigm 전체 구조` 같은 상위 overview topic은 없다. 전체 구조 지식은 우선 GBrain의 `project/exdigm-overview`와 `project/exdigm-architecture`로 관리하고, code_map에는 실제 변경 영향 범위를 찾을 수 있는 기능 topic을 둔다.
