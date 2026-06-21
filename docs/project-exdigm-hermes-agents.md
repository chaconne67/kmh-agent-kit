# Exdigm Hermes Agents

검색 앵커: project/exdigm-hermes-agents, Hermes Agent API, Telegram bot, container agent, AgentProfile, capability catalog.

## Purpose

Exdigm Hermes agents는 Telegram/container agent가 Exdigm 업무를 수행하게 하는 경계다. Agent는 Exdigm capability catalog 안에서 자유롭게 판단하고, 서버는 인증·권한·감사·confirmation·삭제 제한을 강제한다.

## First Targets

- code_map topic: `헤르메스 에이전트 API`, `Telegram 온보딩`, `권한·팀`
- API entrypoint: `accounts/urls_agent.py`
- Router: `accounts/agent_api/router.py`
- Capability registry: `accounts/agent_capabilities/registry.yaml`
- Coverage: `accounts/agent_capabilities/coverage.yaml`
- Prompts: `accounts/agent_prompts/`
- Provisioning: `accounts/services/hermes_provisioning.py`

## Reuse Rules

- `exdigm_request` fallback을 되살리지 않는다.
- Route가 부족하면 우회 script를 만들지 말고 capability를 설계한다.
- Agent API는 기존 service/permission/audit 경로를 재사용해야 한다.
- 삭제 route는 Hermes 메뉴 workflow에 노출하지 않는다.

## Validation

- `tests/test_agent_api_read.py`
- `tests/test_agent_api_business_search.py`
- `tests/test_agent_menu_workflow_contract.py`
- `tests/test_agent_router_phase2_tool_dispatch.py`
- `tests/test_agent_api_no_delete.py`
