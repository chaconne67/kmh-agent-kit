# Agent API, MCP, Menu, Catalog

## Contract

Hermes is the only natural-language route selection subject. The Exdigm server is a data tool: it authenticates, checks scope, validates payloads, executes named routes, and audits. Do not use server-side natural-language router fallback for Hermes business selection.

Allowed Hermes MCP tools:

- `exdigm_agent_menu`
- `exdigm_agent_menu_section`
- `exdigm_agent_menu_task`
- `exdigm_agent_api_route`
- `exdigm_agent_api_call`

Do not revive `exdigm_request` fallback.

## Authentication And Scopes

Agent API uses `Authorization: Bearer <agent_api_key>`.

`AGENT_SCOPES`:

- `agent_me`
- `account_read`
- `account_write`
- `team_read`
- `team_write`
- `notifications_read`
- `news_read`
- `news_write`
- `clients_list`
- `client_write`
- `reference_read`
- `reference_write`
- `projects_list`
- `project_write`
- `candidate_search`
- `candidate_write`
- `actions_write`

Errors:

- Missing bearer: `missing_key`, HTTP 401.
- Unknown fingerprint: `invalid_fingerprint`, HTTP 401.
- Expired key: `expired_key`, HTTP 401.
- User below staff, empty scopes, or missing required scope: `scope_denied`, HTTP 403.
- Wrong method: `method_not_allowed`, HTTP 405.

All success/failure calls write `AgentAuditLog`.

## Runtime Catalog

`_agent_api_catalog_dict()` reads `accounts/urls_agent.py`, view metadata, file fields, capability registry, route hints, schemas, and result shapes. Output goes to `/opt/common/exdigm-agent-api-catalog.json`.

Catalog route fields include:

- `name`, `method`, `path`, `scope`, `group`, `summary`
- `path_params`
- `capability_id`, `job_meaning`, `use_when`, `do_not_use_when`, `required_context`
- `query_schema`, `payload_schema`, `result_shape`
- `read_or_write`
- `risk_level`
- `confirmation_required`
- `returns_download`
- `supports_file_upload`, `file_fields`
- optional `route_choice`, `required_identifiers`, `failure_redirect`, `success_check`

Hot update rule:

- Menu/catalog route changes live in `/opt/common` and are read on each MCP menu/catalog call.
- Image rebuild is not required for menu/catalog changes.
- SOUL.md and SKILL.md can be cached by active Hermes sessions, so profile reprovisioning must reset `sessions/sessions.json` after those change.

## Runtime Menu

`_agent_api_menu_dict()` outputs `/opt/common/exdigm-agent-menu.json`.

First menu order:

- `project_workbench`
- `candidate_lookup`
- `client_management`
- `email_workbench`
- `readonly_context`

Primary Project Workbench sections:

- `project.read`
- `project.requirements`
- `project.lifecycle`
- `project.candidate_discovery`
- `project.pipeline`
- `project.submission`
- `project.resume`
- `project.interview`

The menu hides dashboard, router, delete, low-level write execute, and routes intended only as supporting primitives.

## MCP Server Behavior

`deploy/hermes-agent/exdigm_agent_mcp/server.py`:

- Reads `EXDIGM_AGENT_API_KEY`.
- Reads shared connection config from `/opt/common/exdigm-agent-connection.json` by default.
- Connection config keys are `base_url` and `host`; MCP reads them fresh for each API request so fleet connection changes do not require image rebuild or container recreation.
- Falls back to `EXDIGM_AGENT_API_BASE_URL` and optional `EXDIGM_AGENT_API_HOST` when the connection file is missing, unreadable, malformed, or contains non-string values.
- Uses timeout `150` seconds to support long document/file routes.
- Reads menu/catalog from `EXDIGM_AGENT_MENU_PATH` and `EXDIGM_AGENT_API_CATALOG_PATH`.
- `exdigm_agent_api_call()` finds route by name, renders path params, then calls GET/POST/multipart directly.
- Supports `pk` aliases by path segment, such as `project_id`, `application_id`, `candidate_id`, `client_id`, `submission_id`, `resume_upload_id`, `action_item_id`.
- File upload routes require `file_paths`; non-upload routes reject `file_paths`.

## Hermes Route Selection Flow

For every Exdigm business request:

1. Call `exdigm_agent_menu`.
2. Choose first menu by business context.
3. Call `exdigm_agent_menu_section(menu_id)`.
4. Choose task/section.
5. Call `exdigm_agent_menu_task(task_id)`.
6. Choose route from the task route summaries.
7. Call `exdigm_agent_api_route(route_name)` before execution.
8. Call `exdigm_agent_api_call(route_name, path_params, query, payload, file_paths)`.
9. Report only API-confirmed facts and next action.

Use `route_choice`, `required_identifiers`, `failure_redirect`, and `success_check` over guesswork.

## Write Confirmation

Routes with `confirmation_required: true` must return a confirmation token and not be reported as completed. The user must confirm, then the agent executes through `agent_action_execute`/`agent_write_execute` according to the route contract. One-time tokens expire and must not execute after expiry.

Routes with `confirmation_required: false` may execute directly but must still verify success from response fields.

## Download And Upload

- If `returns_download` is true, show `download.absolute_url` to the Telegram user.
- Do not show only relative `download.url` or server internal paths.
- Uploads require actual file paths inside the Hermes container and matching `file_fields`.

## Domain Glossary

Runtime menu glossary maps natural language to code objects and response fields. This section is the retained human reference for the deleted planning glossary documents.

Key rules:

- Current API response state outranks user wording.
- "후보자" is broad; in a project context distinguish `Candidate`, `ProjectBasketItem`, and `Application`.
- `project_relation=global`: not in project; use `agent_project_candidate_add`.
- `project_relation=basket`: preliminary candidate; get `basket_items[].id` and use `agent_project_basket_promote`.
- `project_relation=application`: already active; use Application routes.
- If `candidate_already_registered` but project detail does not show the candidate, report possible coworker/out-of-scope registration and do not assert preliminary vs active state.
- Say "예비 후보" or "진행 후보"; do not say only "후보자로 등록되어 있습니다."

## Candidate Search Route Boundary

`agent_candidate_search` and `agent_candidate_natural_search` share the `candidate.search` capability but have different route semantics.

- Use `agent_candidate_search` only for literal matching against candidate name, current company, current position, or career tag, optionally narrowed by `project_id`.
- Use `agent_candidate_natural_search` for internal names, short aliases, management categories, status names, recommendation/exclusion meanings, or any candidate-pool condition that is not a direct route schema field.
- Preserve the user's expression in `query.q`; do not invent a missing feature just because the exact label is not in menu text.
- For live debugging, check `AgentAuditLog.route_name`; a broad condition request hitting `/agent/candidates/search` indicates route misselection.

## Current Route Surface Snapshot

Snapshot source: `accounts/urls_agent.py` on 2026-06-19. Runtime catalog is still authoritative.

Runtime catalog count: 161 routes. `accounts/urls_agent.py` also contains `agent_router`, but Hermes menu/catalog generation excludes it.

Core account and Telegram:

- `agent_me`: `/agent/me`
- `agent_dashboard`: `/agent/dashboard`
- `agent_account_access`: `/agent/account/access`
- `agent_account_settings`: `/agent/account/settings`
- `agent_account_profile_update`: `/agent/account/profile/update`
- `agent_account_company_email_update`: `/agent/account/company-email/update`
- `agent_account_notifications_update`: `/agent/account/notifications/update`
- `agent_account_external_site_update`: `/agent/account/external-sites/update`
- `agent_account_telegram`: `/agent/account/telegram`
- `agent_account_telegram_reapply`: `/agent/account/telegram/reapply`
- `agent_account_telegram_restart`: `/agent/account/telegram/restart`
- `agent_account_telegram_offboard`: `/agent/account/telegram/offboard`
- `agent_account_telegram_owner_bind`: `/agent/account/telegram/owner-bind`

Email:

- `agent_email_status`, `agent_email_messages`, `agent_email_message_detail`, `agent_email_send`

Team, clients, references:

- Team: `agent_team_members`, `agent_team_pending_users`, `agent_team_approve_user`
- Clients/contracts: `agent_clients`, `agent_client_search`, `agent_client_create`, `agent_client_detail`, `agent_client_projects`, `agent_client_update`, `agent_client_delete`, `agent_contract_create`, `agent_contract_update`, `agent_contract_delete`
- References: `agent_reference_company_autofill`, `agent_reference_list`, `agent_reference_create`, `agent_reference_import`, `agent_reference_export`, `agent_reference_update`, `agent_reference_delete`

Projects and requirements:

- `agent_projects`, `agent_project_create_draft`, `agent_project_detail`, `agent_project_update_draft`, `agent_project_close_draft`, `agent_project_delete_draft`
- `agent_project_context`, `agent_project_context_save`, `agent_project_context_resume`, `agent_project_context_discard`
- `agent_project_analyze_jd`, `agent_project_jd_results`, `agent_project_matching_results`

Project resumes, postings, interviews, submissions:

- Resumes: `agent_project_drive_picker`, `agent_project_resumes`, `agent_project_resume_upload`, `agent_project_resume_process`, `agent_project_resume_status`, `agent_project_resume_link`, `agent_project_resume_discard`, `agent_project_resume_retry`, `agent_resume_unassigned`, `agent_resume_assign_project`
- Interviews/postings: `agent_project_interviews`, `agent_project_interview_create`, `agent_project_interview_update`, `agent_project_interview_result`, `agent_project_interview_delete`, `agent_project_posting`, `agent_project_posting_generate`, `agent_project_posting_edit`, `agent_project_posting_download`, `agent_project_posting_sites`, `agent_project_posting_site_create`, `agent_project_posting_site_update`, `agent_project_posting_site_delete`
- Submissions/drafts: `agent_project_submissions`, `agent_project_submission_batch_create`, `agent_project_submission_detail`, `agent_project_submission_update`, `agent_project_submission_delete`, `agent_project_submission_feedback`, `agent_project_submission_download`, `agent_submission_draft_detail`, `agent_submission_draft_generate`, `agent_submission_draft_consultation`, `agent_submission_draft_finalize`, `agent_submission_draft_review`, `agent_submission_draft_convert`, `agent_submission_draft_preview`, `agent_application_submission_submit`

Project candidate discovery and Application pipeline:

- Discovery: `agent_project_candidate_search`, `agent_project_candidate_pool_detail`, `agent_project_candidate_add`, `agent_project_active_candidates`, `agent_project_applications`, `agent_project_basket_promote`
- Application: `agent_application_detail`, `agent_application_drop`, `agent_application_restore`, `agent_application_return_to_basket`, `agent_application_hire`, `agent_application_hire_cancel`, `agent_application_skip_stage`, `agent_application_revert_stage`
- Stages: `agent_stage_contact_message_save`, `agent_stage_contact_complete`, `agent_stage_contact_summarize`, `agent_stage_contact_rewrite`, `agent_stage_pre_meeting_schedule`, `agent_stage_pre_meeting_checklist_save`, `agent_stage_pre_meeting_record`, `agent_stage_pre_meeting_summarize`, `agent_stage_interview_feedback_save`, `agent_stage_interview_schedule`, `agent_stage_interview_complete`
- Application resumes/meetings/actions: `agent_application_resume_use_db`, `agent_application_resume_request_email`, `agent_application_resume_upload`, `agent_application_recommendation_resume_generate`, `agent_application_meetings`, `agent_meeting_upload`, `agent_meeting_status`, `agent_meeting_apply`, `agent_application_actions`, `agent_project_auto_actions`, `agent_auto_action_apply`, `agent_auto_action_dismiss`

Notifications, news, candidates, extension, voice, generic actions:

- Notifications: `agent_notifications`, `agent_notification_read`, `agent_notification_dismiss`
- News: `agent_news_articles`, `agent_news_article_detail`, `agent_news_article_like`, `agent_news_article_dislike`, `agent_news_sources`, `agent_news_source_create`, `agent_news_source_update`, `agent_news_source_toggle`, `agent_news_source_delete`
- Candidates: `agent_candidate_search`, `agent_candidate_natural_search`, `agent_candidate_detail`, `agent_candidate_resume_source_link`, `agent_candidate_resume_document_generate`, `agent_candidate_create_draft`, `agent_candidate_review_list`, `agent_candidate_review_detail`, `agent_candidate_review_confirm_draft`, `agent_candidate_review_reject_draft`
- Extension/voice: `agent_candidate_extension_auth_status`, `agent_candidate_extension_stats`, `agent_candidate_extension_search`, `agent_candidate_extension_check_duplicate`, `agent_candidate_extension_save_profile`, `agent_candidate_voice_lab_last`, `agent_candidate_voice_lab_upload`, `agent_candidate_voice_transcribe`
- Actions: `agent_write_execute`, `agent_action_create_draft`, `agent_action_complete_draft`, `agent_action_skip_draft`, `agent_action_reschedule_draft`, `agent_action_execute`

To regenerate the complete current list:

```bash
python3 - <<'PY'
from pathlib import Path
import re
text = Path("accounts/urls_agent.py").read_text()
pattern = re.compile(r'path\(\s*"([^"]*)"\s*,\s*agent_api\.([A-Za-z0-9_]+)\s*,\s*name="([^"]+)"', re.S)
for path, view, name in pattern.findall(text):
    print(f"{name}\t/agent/{path}\t{view}")
PY
```
