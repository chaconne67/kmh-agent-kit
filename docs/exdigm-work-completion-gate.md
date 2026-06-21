# Exdigm Work Completion Gate

Exdigm 코드 작업은 코드 수정만으로 끝나지 않는다. 작업 종료 전에 code_map, GBrain, 기존 경로 재사용 여부를 확인해야 한다.

검색 앵커: Exdigm completion gate, 작업 완료 게이트, code_map 갱신, GBrain 갱신, 기존 경로 재사용, 병렬 경로 금지.

## Before Coding

- GBrain에서 `reference/exdigm-smart-targeting-index`와 관련 기능 page를 검색했다.
- `tools.code_map.impact --topic` 또는 `--file`을 실행했다.
- 기존 service, Agent API route, registry, worker, model, template, test를 확인했다.
- 허용 변경 / 금지 변경 / 검증 방법을 잠갔다.

## During Coding

- 새 병렬 실행 경로를 만들지 않았다.
- 같은 업무를 처리하는 기존 service를 재사용했다.
- Agent API 변경이면 `registry.yaml`, `coverage.yaml`, router, prompts, tests를 함께 봤다.
- DB write 디버깅이면 생성 데이터를 정리하고 0건 재조회 계획을 세웠다.

## After Coding

- focused validation을 실행했다.
- 새 기능, route, template, management command, Agent API surface, 핵심 테스트가 생겼으면 `tools/code_map/semantic_topics.toml` 갱신 여부를 판단했다.
- GBrain에 code_map raw output을 그대로 복사하지 않고 distilled targeting 지식만 남겼다.
- code_map을 갱신했다면 다음을 실행했다.

```bash
uv run python -m tools.code_map.inventory --root .
uv run python -m tools.code_map.validate --root .
```

- 설계 이유, 운영 절차, 반복 교훈, code routing 변화가 생겼으면 GBrain 관련 page를 갱신했다.
- code-review-loop를 실행했다.

## Final Report Fields

완료 보고에는 다음을 포함한다.

- 변경한 기존 실행 경로
- 재사용한 service/API/capability
- 새 병렬 경로를 만들지 않았다는 확인
- 실행한 focused checks
- code_map 갱신 여부
- GBrain 갱신 여부

## Stop Conditions

다음이면 완료하지 않는다.

- 어느 코드가 실제 실행 경로인지 확정하지 못했다.
- 같은 업무를 처리하는 새 경로를 만들었다.
- Agent API route를 바꿨는데 capability registry나 tests를 확인하지 않았다.
- UI/template 변경인데 시각 검증을 하지 않았다.
- GBrain 기억과 현재 코드가 충돌하는데 정리하지 않았다.
