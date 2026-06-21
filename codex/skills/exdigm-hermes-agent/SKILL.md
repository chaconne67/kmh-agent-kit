---
name: exdigm-hermes-agent
description: Use when creating, changing, operating, debugging, or documenting Exdigm Hermes Telegram employee agents, including BotFather onboarding, profile rendering, Docker provisioning, shared Hermes recipes, MCP tools, Agent API routes/catalog/menu, owner self-bind, key rotation, offboarding, fleet refresh, and stale skill/session troubleshooting.
---

# Exdigm Hermes Agent

Exdigm 직원별 Hermes Telegram 에이전트의 판단 규칙. 파일·route·test 탐색은 코드 지도를 먼저 사용하고, 이 스킬은 Agent API, MCP 메뉴, 프로비저닝, 보안, 운영 판단에 집중한다.

## Start With Code Map

작업 시작 시 먼저 주제 또는 파일 기준으로 네비게이션 지도를 조회한다.

```bash
uv run python -m tools.code_map.impact --topic "헤르메스 에이전트 API"
uv run python -m tools.code_map.impact --topic "Telegram 온보딩"
uv run python -m tools.code_map.impact --topic "권한·팀"
uv run python -m tools.code_map.impact --file accounts/urls_agent.py
```

새 Agent API route, capability metadata, menu/catalog surface, prompt recipe, provisioning file, test가 추가되면 `tools/code_map/semantic_topics.toml`도 함께 갱신한다.

```bash
uv run python -m tools.code_map.inventory --root .
uv run python -m tools.code_map.validate --root .
```

## Core Rule

Exdigm 직원 assistant는 직원 1명당 `AgentProfile` 1개, Docker container 1개, Hermes data directory 1개, Telegram bot 1개다.

Exdigm app은 onboarding state, credential, Agent API authorization, Docker provisioning, shared runtime artifact를 소유한다. Hermes는 직원 컨테이너 안의 live conversation loop를 소유한다.

## Source Order

1. 현재 코드 `/home/chaconne/exdigm`가 최우선이다.
2. recipe prompt 원본은 `accounts/agent_prompts/`이며 app container에는 `/opt/agent-prompts`로 mount된다.
3. runtime common artifact의 소스는 `accounts/services/hermes_provisioning.py::_render_common_files()`다.
4. 운영 설명은 이 스킬의 `references/`를 참고한다.

필요할 때만 아래 reference를 읽는다.

- `references/architecture.md`: 구조와 source map
- `references/onboarding-provisioning-ops.md`: BotFather, profile, Docker provisioning, owner-bind, operations
- `references/agent-api.md`: Agent API, MCP tools, catalog/menu, route surface
- `references/troubleshooting.md`: stale skill/session, deployment smoke, incident handling

## Agent API Rules

- Hermes가 자연어로 route를 고르고, Exdigm server는 지정된 route를 인증·scope 확인·payload 검증·실행·감사만 한다.
- Hermes business work는 `exdigm_agent_menu*`와 `exdigm_agent_api_*` 도구를 통해 수행한다.
- 서버 측 자연어 fallback이나 `exdigm_request` fallback을 되살리지 않는다.
- Agent API catalog route metadata는 route 단위다. capability 수준의 write/confirmation flag를 GET route에 복사하지 않는다.
- Delete route는 Hermes menu workflow에 노출하지 않는다.
- 다운로드 응답은 상대 `download.url`이나 내부 path가 아니라 `download.absolute_url`을 Telegram 사용자에게 보여준다.
- 업로드 route는 Hermes container 내부 실제 file path와 catalog의 `file_fields`가 맞아야 한다.

허용 MCP tool:

- `exdigm_agent_menu`
- `exdigm_agent_menu_section`
- `exdigm_agent_menu_task`
- `exdigm_agent_api_route`
- `exdigm_agent_api_call`

## Menu And Glossary Rules

- menu/catalog 변경은 `/opt/common` artifact로 갱신되며 MCP menu/catalog call마다 다시 읽힌다.
- 사용자의 "후보자" 표현은 넓다. 프로젝트 맥락에서는 `Candidate`, `ProjectBasketItem`, `Application`을 구분한다.
- 후보자 단독 검색에서 `agent_candidate_search`는 후보자명/회사/직무/태그 literal 검색만 담당한다.
- 내부 명칭, 짧은 약칭, 관리 분류, 상태명, 추천/배제 의미처럼 route schema에 직접 없는 후보자 조건은 `agent_candidate_natural_search`로 사용자 표현을 `query.q`에 그대로 전달한다.
- `project_relation=global`이면 `agent_project_candidate_add` 대상이다.
- `project_relation=basket`이면 예비 후보이며 `basket_items[].id`로 `agent_project_basket_promote`를 사용한다.
- `project_relation=application`이면 이미 진행 후보이며 Application route를 사용한다.
- `candidate_already_registered`인데 project detail에 보이지 않으면 coworker/out-of-scope 가능성을 보고하고 예비/진행 상태를 단정하지 않는다.
- 사용자에게는 "예비 후보" 또는 "진행 후보"처럼 상태를 구분해 말한다.

## Recipe Vs Tool Changes

Hermes 변경은 recipe와 tool로 나눈다.

- Recipe: `SOUL.md`, `exdigm-work` `SKILL.md`, `WORKFLOW.md`, menu/catalog text처럼 자주 튜닝하는 instruction artifact.
- Tool: Django Agent API view, MCP server behavior, Docker image/entrypoint, DB schema 같은 코드 capability.

Hermes 운영 반영은 사람이 단계를 옵션으로 고르지 않는다. 기본 명령은 항상 아래 단일 자동 경로다.

```bash
scripts/deploy_hermes.sh
```

`scripts/deploy_hermes.sh`는 이미지, `/opt/common`, profile 재적용, recipe refresh를 순서대로 실행하되 각 단계가 fingerprint로 no-op 여부를 판단한다.

`HERMES_RESTART_AGENTS=true`는 common artifact 변경 뒤 active gateway를 즉시 restart해야 할 때만 쓰고, `HERMES_FORCE_AGENT_IMAGE_BUILD=true`는 같은 image fingerprint라도 강제 rebuild가 필요할 때만 쓴다.

`scripts/refresh_hermes_recipes.sh`는 하위 live-refresh 도구다. `deploy_hermes.sh`가 호출하면 common artifact 변경 여부를 `HERMES_FORCE_RECIPE_REFRESH`로 전달해 `exdigm-work`/menu/catalog 변경도 stale session marker를 쓰게 한다.

Tool 변경은 deploy/provisioning과 관련 테스트가 필요하다.

## Onboarding And Provisioning Rules

- onboarding 흐름은 BotFather token input → token validation → `AgentProfile`/`AgentCredential` 저장 → Agent API key issue → Docker provisioning → Telegram `/start` owner self-bind 순서다.
- BotFather token은 Exdigm secure input 경로로만 받고, 실제 token을 붙여 넣거나 로그에 남기지 않는다.
- Telegram authorization은 numeric user ID 기준이다.
- `code_execution`은 Hermes profile config에서 비활성화되어야 한다.
- Terminal은 diagnostic only다. Exdigm business work는 Agent API route로만 수행한다.
- provisioning 변경은 `render_profile_bundle()`과 `_render_common_files()`를 재사용한다.
- SSH provisioning 또는 Hermes 내부 multi-profile model을 되살리지 않는다.

## Runtime Paths

- shared menu/skill files는 `/var/lib/exdigm/hermes-common`에 있고, agent container에는 `/opt/common`으로 read-only mount된다.
- host-managed per-profile config는 `/var/lib/exdigm/hermes-config/<profile_name>`에 있고, agent container에는 `/opt/config`로 read-only mount된다.
- per-user runtime data는 `/var/lib/exdigm/hermes-agents/<profile_name>`에 있고, agent container에는 `/opt/data`로 read-write mount된다.
- entrypoint는 `/opt/config/config.yaml`과 `.env`를 `/opt/data`로 복사하고, `/opt/config/SOUL.md`와 `.no-bundled-skills`를 `/opt/data`에 symlink한다.
- `HERMES_BUNDLED_SKILLS`는 빈 디렉터리를 가리켜야 한다. `config.yaml`에 bundled skill name을 나열하지 않는다.
- entrypoint는 agent-created custom skills를 보존하되 예약 이름 `skills/exdigm-work`가 symlink가 아니면 제거하고 `/opt/common/skills/exdigm-work` symlink로 복구한다.
- reprovisioning은 profile fingerprint로 stale `/opt/data/.skills_prompt_snapshot.json`, `/opt/data/sessions/sessions.json`을 제거해야 하며, `/opt/data/skills` 전체 wipe를 되살리지 않는다.

## Stale Behavior Rules

Recipe refresh 후 stale behavior가 남으면 active profile의 실제 runtime 파일을 확인한다.

- `/opt/config/SOUL.md`
- `/opt/config/.exdigm-profile-fingerprint`
- `/opt/data/SOUL.md`
- `/opt/common/skills/exdigm-work/SKILL.md`
- `/opt/data/.skills_prompt_snapshot.json`
- `/opt/data/sessions/sessions.json`
- `/opt/data/.exdigm_recipe_refresh_epoch`

사용자에게 `/new`를 실행하라고 요구하지 않는다. Exdigm wrapper가 refresh marker를 보고 다음 메시지에서 내부 fresh-session reset을 수행해야 한다.

## Verification

상황에 맞는 코드 지도 결과와 focused 테스트를 우선한다.

```bash
uv run python -m tools.code_map.impact --topic "헤르메스 에이전트 API"
uv run python -m tools.code_map.validate --root .
uv run pytest -q \
  tests/test_agent_docker_profile_apply.py \
  tests/accounts/test_telegram_onboarding.py \
  tests/test_refresh_hermes_fleet_command.py \
  tests/test_agent_mcp_candidate_tools.py \
  tests/test_agent_menu_workflow_contract.py
```

운영 검증은 사용자가 live operation을 요청했거나 실제 운영 장애 확인이 필요한 경우에만 수행한다.
