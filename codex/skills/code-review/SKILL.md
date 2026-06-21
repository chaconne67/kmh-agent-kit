---
name: code-review
description: Review a GitHub pull request or local diff for high-confidence bugs and project-instruction violations. Use when the user asks for code-review, PR review, review this PR, or wants an automated reviewer pass before commenting on a PR.
---

# Code Review

Review only issues a senior engineer would expect to fix before merge.

## Source

This skill was adapted from the Claude Code `code-review` command copied from the production server. The original command is preserved at `references/claude-code-review-command.md`.

Read the reference only when you need the original scoring rubric or PR comment format.

## Workflow

1. Determine the target:
   - For a PR, use `gh pr view`, `gh pr diff`, and repository metadata.
   - For local work, use `git diff` and the user-specified file scope.
2. Check eligibility before reviewing:
   - Stop if the PR is closed, draft, automated, trivial, or already reviewed by this agent.
   - Do not post a GitHub comment unless the user explicitly asks.
3. Gather applicable project instructions:
   - Read root `AGENTS.md` or `CLAUDE.md`.
   - Read any nested instruction files that apply to changed files.
4. Review for high-confidence findings:
   - Project-instruction violations that directly apply to the changed code.
   - Functional bugs introduced by the changed lines.
   - Bugs visible from nearby context, git history, prior PR comments, or code comments.
5. Filter aggressively:
   - Exclude pre-existing issues, likely intentional behavior changes, nitpicks, pure style, missing tests unless required by instructions, and failures that CI should catch.
   - Keep only findings you would score at least 80/100 confidence after checking evidence.
6. Report findings first:
   - Include severity, file/line, concrete failure mode, and the smallest useful fix direction.
   - If no findings pass the confidence bar, say that clearly and mention remaining review limits.

## GitHub Comment Format

When the user asks you to comment on the PR:

- Re-check eligibility immediately before posting.
- Use `gh pr comment` or the available GitHub tool.
- Keep the comment brief.
- Cite permanent links with full commit SHA and line ranges.
- Do not include Claude-specific generated-by footers.

## Output Shape

Use this order:

1. Findings, ordered by severity.
2. Open questions or assumptions.
3. Brief summary or test gaps only after findings.
