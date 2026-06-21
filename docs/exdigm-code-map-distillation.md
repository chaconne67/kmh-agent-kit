# Exdigm Code Map Distillation

`tools/code_map`은 현재 코드의 raw map이다. GBrain에 필요한 것은 raw map이 아니라 에이전트가 작업을 시작할 때 잘못된 경로로 가지 않게 하는 distilled map이다.

검색 앵커: Exdigm code_map distillation, raw map 정제, target map, 정밀 타겟팅, code_map 노이즈 제거.

## Why

Exdigm 코드는 이미 기능과 파일이 많다. raw code_map 결과를 그대로 GBrain에 넣으면 검색 결과가 파일 목록 dump가 되고, 에이전트는 다시 새 코드를 만들거나 잘못된 helper를 먼저 보게 된다.

따라서 GBrain에는 “어디부터 봐야 하는가”와 “어떤 기존 경로를 재사용해야 하는가”만 남긴다.

## Keep

- 사용자 요청이 들어왔을 때 첫 번째로 열 entrypoint
- 업무 상태를 바꾸는 domain service
- Agent API route, capability registry, prompt surface
- worker/management command 시작점
- 대표 business-observable test
- 새 병렬 경로를 막는 reuse rule
- 과거 실패에서 얻은 root cause와 재발 방지 규칙

## Drop

- migrations
- admin boilerplate
- `__init__.py`
- import-only barrel files
- 같은 계층의 template partial 전체 목록
- static/build output
- 단순 helper 전체 나열
- 현재 코드로 바로 조회 가능한 장황한 파일 목록

## Selection Question

각 항목을 남기기 전에 묻는다.

```text
이 항목이 없으면 에이전트가 잘못된 실행 경로를 선택하거나 기존 코드를 재사용하지 못할 가능성이 큰가?
```

답이 아니면 GBrain index에 넣지 않는다. 필요하면 작업 중 `tools.code_map.impact`로 다시 조회한다.

## Distilled Page Shape

```markdown
# Feature Name

검색 앵커:

## First Targets
- code_map topic
- entrypoints
- domain services
- Agent/API/worker surfaces

## Reuse Rules
- 새로 만들지 말고 재사용할 경로

## Validation
- 대표 tests
- business-observable checks

## Known Failure Modes
- 과거 실패와 원인
```
