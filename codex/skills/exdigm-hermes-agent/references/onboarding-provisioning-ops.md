# Onboarding, Provisioning, Operations

## Employee Onboarding Flow

1. Employee opens Telegram setup in Exdigm settings.
2. UI/LLM guide walks through Telegram install, BotFather, `/newbot`, bot name, username ending in `bot`, and token copy.
3. Employee pastes BotFather HTTP API token into Exdigm settings, not into Telegram chat.
4. `inspect_bot_token()` calls Telegram `getMe` to verify token and read bot ID/username.
5. `_store_verified_bot_token()` creates or updates `AgentProfile` and `AgentCredential`, stores encrypted token, sets status `telegram_token_ready`.
6. `_stamp_owner_bind_nonce()` writes a 10-minute nonce and calls Telegram `deleteWebhook(drop_pending_updates=false)`.
7. `_provision_profile()` issues Agent API key if missing, sets status `provisioning`, and runs Docker provisioning when `AGENT_PROVISIONING_AUTO_APPLY=true`.
8. Completed UI shows `https://t.me/<bot_username>`.
9. Employee opens the bot and presses Telegram start. The wrapper turns `/start` into `안녕하세요`.
10. `exdigm_self_bind.py` binds the first valid human DM sender ID through `/agent/account/telegram/owner-bind`.

There is no old Exdigm `/start <인증코드>` step in the Hermes employee flow.

## BotFather Guidance Rules

- BotFather is Telegram's official bot-making account.
- User must select the official BotFather with the blue verification badge.
- `/newbot` must include the slash.
- Bot display name is free; username must be globally unique and end with `bot`.
- Token shape is roughly `digits:long_string`; paste the full token from the digit before `:` through the last character.
- If a user pastes a username instead of token, explain that the token contains digits, colon, and a long string.
- Never echo the real token back.
- Official references to check when changing copy: `https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram` and `https://core.telegram.org/bots/features#botfather`.

## Docker Provisioning Contract

Defaults in `accounts/services/hermes_provisioning.py`:

- API base URL: `https://api.exdigm.kr/agent`
- Docker image fallback: `nousresearch/hermes-agent:main`
- Docker base dir: `/var/lib/exdigm/hermes-agents`
- Docker config dir: `/var/lib/exdigm/hermes-config`
- Docker common dir: `/var/lib/exdigm/hermes-common`
- Docker network: `Exdigm_net`
- Container name: `exdigm-agent-<safe_profile_name>`

Local development `.env.example` uses:

- `AGENT_PROVISIONING_AUTO_APPLY=true`
- `AGENT_DOCKER_IMAGE=exdigm-hermes-gateway:dev`
- `AGENT_DOCKER_NETWORK=host`
- `AGENT_API_BASE_URL=http://127.0.0.1:8000/agent`
- production override suggests `AGENT_API_BASE_URL=http://exdigm_app:8000/agent` and `AGENT_DOCKER_NETWORK=Exdigm_net`

Provisioning prerequisites:

- canonical profile name
- role `STAFF` or `BOSS`
- credential row
- BotFather token
- Agent API key
- all `AGENT_SCOPES`

Network safety:

- Loopback API URLs are rejected on non-host Docker networks with `unsafe_agent_api_base_url_for_docker_network`.
- Host network with loopback is rejected if the API socket cannot be reached, with `unreachable_loopback_agent_api_for_host_network`.
- If API host contains `_`, `EXDIGM_AGENT_API_HOST` is derived from `PUBLIC_DOWNLOAD_BASE_URL` or `SITE_URL` for Host header override.

Docker apply writes host-owned config files under `hermes-config`, rewrites common files, fingerprints config/image inputs, preserves agent-owned runtime data under `hermes-agents`, and recreates the container only when config/image inputs changed.

The apply script must not write arbitrary files. Profile allowlist: `config.yaml`, `SOUL.md`, `.env`, `.no-bundled-skills`, and managed `.exdigm-profile-fingerprint`. Common allowlist: shared `exdigm-work`, MCP server, catalog, menu, and connection JSON.

Docker run mounts config read-only and runtime data read-write:

```text
docker run -d --name exdigm-agent-<profile> --restart unless-stopped
  --memory 512m --cpus 0.5 --env-file <config_home>/.env
  -e HERMES_HOME=/opt/data -e HERMES_CONFIG_HOME=/opt/config
  -e HERMES_COMMON_HOME=/opt/common
  -v <config_home>:/opt/config:ro
  -v <data_home>:/opt/data:rw
  -v <common_dir>:/opt/common:ro
  [--network <network>]
  <image>
```

The apply script must not include secret values in static script text or error codes.

## Wrapper Entrypoint Contract

`deploy/hermes-agent/entrypoint.sh`:

- Sets `HERMES_HOME=/opt/data`, `HERMES_CONFIG_HOME=/opt/config`, `HERMES_COMMON_HOME=/opt/common`, and XDG dirs.
- Requires `/opt/config/config.yaml`, `/opt/config/SOUL.md`, `/opt/config/.env`, `/opt/common/skills/exdigm-work`, and `/opt/common/exdigm-agent-mcp/server.py`.
- Copies `config.yaml` and `.env` into `/opt/data`; symlinks `SOUL.md` and `.no-bundled-skills` from `/opt/config`.
- Removes stale `sessions/sessions.json` and `.skills_prompt_snapshot.json` when `.exdigm-profile-fingerprint` changes.
- Preserves agent-created custom skills; only a non-symlink `/opt/data/skills/exdigm-work` is removed before recreating the shared symlink.
- Sets `HERMES_BUNDLED_SKILLS` to an empty directory.
- Patches Telegram polling to keep pending updates.
- Patches `/start` into first greeting text.
- Patches self-bind hook into Hermes gateway authorization.
- Runs `rtk init --agent hermes --auto-patch`.
- Starts `/opt/hermes/.venv/bin/hermes gateway run` as `hermes` user.

## Owner Self-Bind

Self-bind allows provisioning before the numeric Telegram sender ID is known.

Conditions:

- `TELEGRAM_ALLOWED_USERS` is empty.
- Source is Telegram, human, one-to-one chat.
- Sender ID is numeric.
- Nonce/deadline from `.env` is valid.
- `/agent/account/telegram/owner-bind` accepts the sender ID and nonce.

Behavior:

- On success, writes `/tmp/owner_bind_owner.txt`, sets `TELEGRAM_ALLOWED_USERS`, and current message is accepted.
- On 409 conflict, reject silently and log owner conflict.
- On 5xx or network failure, retry on next message.
- On invalid/expired nonce, silent drop.

The Django route must clear nonce fields and persist the sender ID; if the profile already has another sender ID, return conflict.

## Operations

Hermes deploy:

- Use `scripts/deploy_hermes.sh` without arguments. Do not choose deployment levels with command-line options.
- The script always runs image build/reuse, `/var/lib/exdigm/hermes-common` refresh, active profile reapply, and recipe refresh in that order.
- Each step uses fingerprints to skip unchanged work; changed image/profile inputs recreate only affected profiles.
- Common artifact changes set `HERMES_FORCE_RECIPE_REFRESH=true` for recipe refresh so `exdigm-work`, menu, catalog, or MCP changes clear stale skill/session state even when `SOUL.md` did not change.
- Set `HERMES_RESTART_AGENTS=true` only when active gateways should restart immediately after common artifact changes.
- Set `HERMES_FORCE_AGENT_IMAGE_BUILD=true` only when the wrapper image must rebuild despite an existing matching image tag.

Recipe refresh:

- `scripts/refresh_hermes_recipes.sh` is a lower-level live-refresh tool used by `scripts/deploy_hermes.sh`.
- The script verifies `AGENT_PROMPTS_DIR`, can refresh `/var/lib/exdigm/hermes-common`, writes active profile `SOUL.md`, removes `sessions/sessions.json`, removes `.skills_prompt_snapshot.json`, and writes `.exdigm_recipe_refresh_epoch` for changed or forced profiles. It does not restart active Hermes gateways.
- `SOUL.md` is written under `/var/lib/exdigm/hermes-config/<profile>`; runtime reset files stay under `/var/lib/exdigm/hermes-agents/<profile>`.
- The script intentionally does not call `docker rm`, `docker run`, or `provision_agent_profile`.
- By default the script sends a Telegram notice through each profile's own bot token without printing tokens. Set `HERMES_RECIPE_NOTIFY=false` to skip notices.
- After recipe refresh, the Exdigm Hermes wrapper consumes `.exdigm_recipe_refresh_epoch` on the next Telegram message, clears the cached agent/session boundary, and creates a fresh Hermes session from the current `/opt/data/SOUL.md` and `/opt/common/skills/exdigm-work`.

Reapply:

- `accounts/services/agent_recovery.py::reapply_agent_profile()` delegates to `provision_agent_profile()`.

Restart:

- Validates canonical profile name, runs `docker restart exdigm-agent-<profile>`, marks active on success.

Offboard:

- Revokes credentials.
- Runs `docker rm -f exdigm-agent-<profile>`.
- Marks status failed with `agent_credentials_revoked`.

Agent API key rotation:

- `reissue_agent_api_key()` preserves current scopes, issues a new `exk_live_...` key, marks `rotated_at`, and reprovisions profile.
- `revoke_agent_credentials()` clears encrypted token/key, fingerprints, scopes, expiry, sets status failed.

Fleet common refresh:

```bash
uv run python manage.py refresh_hermes_fleet --indent 2
```

The command emits a JSON object keyed by destination path under `/opt/common`. `scripts/deploy_hermes.sh` and `scripts/refresh_hermes_recipes.sh` call it; normal operators should run `scripts/deploy_hermes.sh`.
