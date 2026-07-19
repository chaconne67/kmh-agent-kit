# Troubleshooting And Verification

## Production Incident: `himalaya` Reappeared

Symptom:

- Telegram user asked whether email sending was possible.
- Hermes answered based on generic `himalaya` CLI instead of Exdigm company email status.

Confirmed causes:

1. Local committed code and deployed app image differed.
2. Operating app container lacked current `SOUL.md` X-Dime operating model and bundled skill pruning logic.
3. Profile reprovisioning from stale app image produced stale `/opt/data`.
4. Hermes startup `tools.skills_sync.sync_skills()` recreated bundled skills under nested paths such as `/opt/data/skills/email/himalaya`.
5. Even after skill files were removed, Telegram DM reused old session ID and old session history/system prompt in `/opt/data/sessions/sessions.json` and `state.db`.

Required prevention:

- Wrapper entrypoint must set `HERMES_BUNDLED_SKILLS` to an empty directory.
- Wrapper entrypoint must preserve agent-created custom skills and only replace reserved `skills/exdigm-work` when it is not the shared symlink.
- Wrapper entrypoint must delete stale `.skills_prompt_snapshot.json` and `/opt/data/sessions/sessions.json` when the profile fingerprint changes.
- Do not list bundled skill names in `config.yaml.skills.disabled`; hiding by empty bundled-skill directory avoids exposing names to the model.
- Deployment is not complete at git commit/push. It requires app image deploy, active profile reprovision, and active `/opt/data` verification.

## Debug Order For Telegram Agent Issues

1. Identify the actual bot/profile/container that handled the Telegram DM. Do not guess from one profile.
2. Classify the change before choosing the operation:
   - Recipe change: `SOUL.md`, `exdigm-work` `SKILL.md`, `WORKFLOW.md`, route-selection instructions, business interpretation rules.
   - Tool change: Django Agent API code, MCP server behavior, Docker image/entrypoint, DB schema, capability implementation.
3. For recipe changes, verify the app container reads the mounted prompt source:
   - `AGENT_PROMPTS_DIR=/opt/agent-prompts`
   - `accounts.agent_prompts.load_prompt("soul.md")` contains the expected needle.
   - run `scripts/deploy_hermes.sh`.
4. For tool changes, check operating app container files and deployed image code, not only local files:
   - `/app/accounts/services/hermes_profile.py`
   - `/app/accounts/services/hermes_provisioning.py`
   - `/app/deploy/hermes-agent/exdigm_agent_mcp/server.py`
5. For every active Hermes container, inspect `/opt/data`:
   - `config.yaml`
   - `.env` existence and permissions, without printing secrets
   - `SOUL.md`
   - `skills/`
   - `.skills_prompt_snapshot.json`
   - `sessions/sessions.json`
   - `.exdigm_recipe_refresh_epoch`
6. If `/opt/data/skills/email/himalaya` exists, suspect bundled skill sync and `HERMES_BUNDLED_SKILLS`.
7. If `/opt/data/SOUL.md` and `/opt/common/skills/exdigm-work/SKILL.md` are current but the answer is stale, suspect active session history. Recipe refresh should remove `sessions/sessions.json` and write `.exdigm_recipe_refresh_epoch`; the wrapper then starts a fresh session on the next Telegram message.
8. Check Agent API response before claiming business capability. Example: email sending requires `agent_email_status` and `company_email.can_send`.

## Candidate Search Route Misselection

Symptom:

- A user asks for a short internal candidate-pool term, management category, status name, recommendation/exclusion meaning, or broad condition.
- Hermes calls `agent_candidate_search` (`/agent/candidates/search`) and reports no keyword match instead of using natural-language candidate search.

Required diagnosis:

- Check `AgentAuditLog.route_name` for the actual profile and timestamp.
- If the request is not literal candidate name/company/position/tag matching, `agent_candidate_search` is the wrong route.
- The generated catalog/menu must steer such requests to `agent_candidate_natural_search`, preserving the user expression in `query.q`.

Prevention:

- Keep `agent_candidate_search` route semantics narrow: literal candidate name, company, position, or career tag only.
- Keep `agent_candidate_natural_search` broad: internal names, short aliases, management categories, status names, recommendation/exclusion meanings, and route-schema-missing candidate conditions.
- Do not fix this by enumerating every possible business nickname in prompts; fix the route boundary and delegate condition interpretation to the candidate search API.

## Recipe Refresh Regression

Symptoms:

- Local `SOUL.md` or skill changed, but Kate/Jessica still answers with old reasoning.
- App image redeploy feels necessary even though only prompt text changed.

Required checks:

- The production stack must mount `/home/chaconne/exdigm/accounts/agent_prompts:/opt/agent-prompts:ro`.
- The app container must set `AGENT_PROMPTS_DIR=/opt/agent-prompts`.
- `scripts/deploy_hermes.sh` takes no command-line options; it always runs the safe automatic decision path and lets fingerprints skip unchanged work.
- Common artifact changes must pass `HERMES_FORCE_RECIPE_REFRESH=true` into `scripts/refresh_hermes_recipes.sh` so `exdigm-work`, menu, catalog, or MCP changes write `.exdigm_recipe_refresh_epoch` even when `SOUL.md` is unchanged.
- `scripts/refresh_hermes_recipes.sh` must use `docker exec -i` for heredoc Python checks; otherwise `python -` can receive empty stdin and silently skip verification.
- Django `manage.py shell -c` JSON producers must use `--no-imports` to avoid auto-import banner text corrupting JSON payloads.
- Profile recipe writes should run inside the app container with permissions that can write `/var/lib/exdigm/hermes-config/<profile>/SOUL.md`; runtime resets still target `/var/lib/exdigm/hermes-agents/<profile>`.
- Removing `sessions/sessions.json` is not enough while the gateway process is running. Recipe refresh must also write `.exdigm_recipe_refresh_epoch`; the Exdigm Hermes wrapper reads that marker on the next user message and performs the fresh-session reset in memory.
- Telegram recipe refresh notices may be sent through profile `.env` values, but scripts must never print `TELEGRAM_BOT_TOKEN` or the full `.env`.
- `scripts/deploy_hermes.sh` must not leave a `RETURN` trap that references a local `payload_file`; clean the temporary payload explicitly before returning.

## Route Metadata Regression

Problem:

- Hermes said a project had no assigned consultant though Agent API returned `assigned_consultants`.

Root cause:

- Generated catalog mixed capability-level write/confirmation metadata into GET route metadata.

Prevention:

- `read_or_write` must come from HTTP method.
- `confirmation_required` must come from `_agent_route_requires_confirmation(route_name)`.
- GET result shapes must not contain confirmation-token hints.
- Debug generated `exdigm-agent-api-catalog.json`, not only Django views.

## Stale Stash / Deployment Regression

Risk:

- An old stash can apply cleanly and silently remove newer Hermes deployment safety logic.

Prevention:

- Before trusting old stash changes, compare stash age/base and overlapping files against `HEAD`.
- Treat large `deploy.sh` deletions as regression until proven intentional.
- Run focused Docker/provisioning/deploy contract tests.

## Focused Verification Commands

Profile rendering and security:

```bash
uv run pytest -q tests/test_hermes_profile_renderer.py tests/test_hermes_profile_security_template.py
```

Docker provisioning and container image:

```bash
uv run pytest -q tests/test_agent_docker_profile_apply.py tests/test_agent_container_image.py
```

Onboarding and status:

```bash
uv run pytest -q tests/accounts/test_telegram_onboarding.py tests/test_agent_profile_status_display.py tests/test_agent_offboarding.py tests/test_agent_manual_reapply.py tests/test_agent_api_key_reissue.py
```

Agent API auth/write/menu/MCP:

```bash
uv run pytest -q tests/accounts/test_agent_api_auth.py tests/test_agent_api_write_confirmation.py tests/test_agent_api_no_delete.py tests/test_agent_mcp_candidate_tools.py tests/test_agent_menu_workflow_contract.py tests/test_refresh_hermes_fleet_command.py
```

Representative business API checks:

```bash
uv run pytest -q tests/test_agent_api_projects.py tests/test_agent_api_candidate_read.py tests/test_agent_api_email.py tests/test_agent_api_submissions.py tests/test_agent_api_news_actions.py tests/test_agent_api_dashboard.py
```

Acceptance/smoke:

```bash
uv run pytest -q tests/test_hermes_acceptance_gate.py
uv run python manage.py check
uv run python manage.py migrate --check
git status --short
```

## Live Container Checks

Use only when live operational verification is requested:

```bash
docker ps --format '{{.Names}} {{.Image}} {{.Status}}'
docker inspect -f '{{.State.Running}}' exdigm-agent-<profile-name>
docker logs --tail=200 exdigm-agent-<profile-name>
docker exec exdigm-agent-<profile-name> sh -lc 'find /opt/data/skills -maxdepth 3 -type f -o -type l'
docker exec exdigm-agent-<profile-name> sh -lc 'test ! -e /opt/data/.skills_prompt_snapshot.json'
docker exec exdigm-agent-<profile-name> sh -lc 'test ! -e /opt/data/sessions/sessions.json'
docker exec exdigm-agent-<profile-name> sh -lc 'test -e /opt/data/.exdigm_recipe_refresh_epoch'
```

Do not print `.env` values or real tokens.
