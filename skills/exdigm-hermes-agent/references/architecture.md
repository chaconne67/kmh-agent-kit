# Architecture

## Current Shape

- Product: Exdigm employee personal assistant over Telegram.
- Runtime: Exdigm wrapper Docker image `exdigm-hermes-gateway:dev` over `nousresearch/hermes-agent:main`.
- One employee maps to one `AgentProfile`, one `AgentCredential`, one container, one `/opt/data`, and one Telegram bot.
- Hermes internal profiles are not used for employees. `profile_name` only makes safe container and data directory names.
- Profile name: `AgentProfile.profile_name_for(user)` -> `exdigm-employee-<user.pk>`.
- Runtime user inside official Hermes image is UID/GID `10000`; host-managed config files must be readable through the entrypoint, and `.env` stays `0600`.
- Default model provider is Gemini, model `gemini-3.1-flash-lite`.
- Timezone is `Asia/Seoul`.

## Main Source Files

| Path | Role |
|---|---|
| `accounts/models.py` | `AgentProfile`, `AgentCredential`, `AgentAuditLog`, router session state, write confirmation state. |
| `accounts/services/telegram_onboarding.py` | Employee-facing Telegram setup flow and BotFather token handling. |
| `accounts/services/hermes_profile.py` | Deterministic Hermes profile/common artifact rendering. |
| `accounts/services/hermes_provisioning.py` | Docker apply, fleet common artifact rendering, Agent API catalog/menu generation. |
| `accounts/services/agent_api_keys.py` | Agent API key issue, reissue, revoke. |
| `accounts/services/agent_recovery.py` | Reapply, restart, offboard operations. |
| `accounts/services/agent_profile_status.py` | Status display for UI. |
| `deploy/hermes-agent/Dockerfile` | Wrapper image with Node, RTK, self-bind helper, entrypoint. |
| `deploy/hermes-agent/entrypoint.sh` | Runtime patching, bundled skill hiding, custom skill preservation, Hermes gateway start. |
| `deploy/hermes-agent/exdigm_self_bind.py` | First Telegram sender numeric ID owner-bind helper. |
| `deploy/hermes-agent/exdigm_agent_mcp/server.py` | Hermes MCP tools that read menu/catalog and call Agent API. |
| `accounts/agent_prompts/soul.md` | X-Dime persona and state-first behavior. |
| `accounts/agent_prompts/exdigm_work_skill.md` | Shared Hermes `exdigm-work` skill template. |
| `accounts/agent_prompts/exdigm_business_workflow.md` | Project/Candidate/Application/Submission workflow model. |
| `accounts/urls_agent.py` | Agent API route surface. |
| `accounts/agent_api/` | Agent API implementation by domain. |
| `accounts/agent_capabilities/registry.yaml` | Capability metadata used by catalog generation. |
| `accounts/templates/accounts/partials/settings_telegram.html` | Token input UI and completed bot link. |
| `accounts/templates/accounts/partials/_telegram_setup_guide.html` | Employee BotFather guide. |
| `accounts/management/commands/refresh_hermes_fleet.py` | Emits common artifacts JSON for deployment refresh. |

## Data Model

`AgentProfile`

- `role`: `STAFF` or `BOSS`.
- `status`: `pending`, `telegram_token_ready`, `telegram_id_ready`, `provisioning`, `active`, `failed`.
- Telegram fields: `telegram_user_id`, `telegram_bot_id`, `telegram_bot_username`, `telegram_capture_nonce`, `telegram_capture_expires_at`.
- `telegram_capture_last_update_id` is deprecated but kept until the deferred migration is safe.
- `profile_name_for(user)` returns `exdigm-employee-<user.pk>`.
- `role_for_user(user)` requires approved staff; boss level maps to `BOSS`.

`AgentCredential`

- Stores encrypted BotFather token and encrypted Agent API key.
- Stores token/API key fingerprints, bot token mask, allowed scopes, API key expiry, rotation timestamp.
- `set_agent_api_key()` requires approved staff, expiry, and string scopes.

`AgentAuditLog`

- Every Agent API auth failure/success is logged with endpoint, method, status, result, failure reason, request ID, and key fingerprint prefix.

`AgentWriteConfirmation`

- Dangerous writes return one-time `confirmation_token`; execution happens through the action execute route.

## Generated Artifacts

Runtime instruction artifacts have a hot-swap boundary:

- Local recipe source: `/home/chaconne/exdigm/accounts/agent_prompts`.
- App container mount: `/opt/agent-prompts`.
- Loader: `accounts.agent_prompts.load_prompt()` prefers `AGENT_PROMPTS_DIR` and falls back to packaged image files only when the mounted file is missing.
- Normal Hermes deploy command: `scripts/deploy_hermes.sh`.
- Lower-level recipe refresh tool: `scripts/refresh_hermes_recipes.sh`.

Do not use `/app/accounts/agent_prompts/*.md` as the runtime truth when `AGENT_PROMPTS_DIR=/opt/agent-prompts` is configured.

Host-managed profile config under `/var/lib/exdigm/hermes-config/<profile_name>`:

- `config.yaml`
- `.env`
- `SOUL.md`
- `.no-bundled-skills`
- `.exdigm-profile-fingerprint`

Runtime data under `/var/lib/exdigm/hermes-agents/<profile_name>`:

- `sessions/`
- `state.db`
- `skills/`
- `.skills_prompt_snapshot.json`
- `.exdigm_recipe_refresh_epoch`

Common artifacts under `/var/lib/exdigm/hermes-common`:

- `skills/exdigm-work/SKILL.md`
- `skills/exdigm-work/WORKFLOW.md`
- `exdigm-agent-mcp/server.py`
- `exdigm-agent-api-catalog.json`
- `exdigm-agent-menu.json`
- `exdigm-agent-connection.json`

`SOUL.md`, `SKILL.md`, `WORKFLOW.md`, menu/catalog text, and route semantics in generated catalog/menu are recipes. Agent API route implementations, MCP server code behavior, Docker image/entrypoint behavior, and DB schema are tools. Normal operations use `scripts/deploy_hermes.sh`; it decides rebuild, common refresh, profile reapply, and recipe refresh by fingerprint.

## Profile Config Contract

`render_config_yaml()` sets:

- `agent.max_turns: 90`
- `agent.reasoning_effort: medium`
- `agent.disabled_toolsets: ["code_execution"]`
- memory and user profile enabled
- manual approvals
- secret redaction and Tirith enabled
- Telegram `allow_from: ["${TELEGRAM_ALLOWED_USERS}"]`
- no Telegram admin allowlist
- user command allowlist only `status`
- shared `exdigm-work` skill path `/opt/common/skills/exdigm-work`
- MCP server `exdigm` with menu/catalog paths under `/opt/common`
- shared connection file `/opt/common/exdigm-agent-connection.json`; MCP falls back to env when the file is missing or invalid
- plugin `rtk-rewrite`

Entrypoint materialization:

- `/opt/config/config.yaml` and `.env` are copied into `/opt/data`.
- `/opt/config/SOUL.md` and `.no-bundled-skills` are symlinked into `/opt/data`.
- `/opt/data/skills` is preserved for agent-created skills; reserved `skills/exdigm-work` is forced to a symlink to `/opt/common/skills/exdigm-work`.
- `.exdigm-profile-fingerprint` changes remove `/opt/data/sessions/sessions.json` and `.skills_prompt_snapshot.json`.

## Business Model Embedded In Hermes

- `Project` is one client job order.
- `Candidate` is a person in the global candidate DB.
- `ProjectBasketItem` is a project preliminary candidate.
- `Application` is a project active candidate.
- User-facing stages: `contact -> pre_meeting -> recommendation -> interview -> closing`.
- Discovery happens before `Application`; resume receipt/conversion helps the `recommendation` stage.
- "추천서" is not a customer deliverable. Say "제출용 이력서" or "고객사 제출용 이력서"; "추천 단계" remains a stage name.
