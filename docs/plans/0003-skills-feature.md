# Skills Dev Container Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fetch skills through the public `skills` npm CLI, configured in `devcontainer.json`, and install independent copies for configurable agents.

**Architecture:** Add a separate `skills` Feature with a standard Node Feature dependency. A POSIX entry point ensures Git is available, then a small Node runner resolves the container's remote user and invokes `npx skills add` as that user with argument arrays. Installation happens during the image build, globally within the container user's home.

**Tech Stack:** POSIX shell, Node.js built-ins, npm/npx, Dev Container Features, Docker.

## Global Constraints

- Public reference: `ghcr.io/kubamarchwicki/devcontainer-features/skills:1`; Feature version `1.0.0`.
- `sources` is a string, default empty, containing comma-separated or newline-separated CLI source specifications. Support `owner/repo`, `owner/repo@skill-name`, and repository/tree URLs by forwarding each specification intact to the CLI. Empty sources performs no skill installation.
- `agents` is a string, default `codex,claude-code`, containing comma-separated or whitespace-separated CLI agent IDs; the consumer can replace it in `devcontainer.json`. Explicit `*` is allowed. Reject an empty agent list when installing sources.
- `version` is a string, default `latest`, selecting the npm `skills` CLI version. It is independent of the source revision and Feature version.
- Every skills install uses `--global --copy --yes` and explicit `--agent` arguments. Never use `--all`, which would override the requested agents.
- Use `npx --yes --package skills@<version> skills add <source> ...`, passing arguments without shell evaluation. Set `npm_config_engine_strict=true` for the child process.
- Depend on `ghcr.io/devcontainers/features/node:1` with default options. This supplies current LTS Node.js; skills@1.5.25 currently requires Node >=22.20.0. Do not change Codex's distribution-package bootstrap policy.
- Install as `_REMOTE_USER`, falling back to `_CONTAINER_USER` and then `root`. Resolve its UID, GID, and home from `/etc/passwd`; use `_REMOTE_USER_HOME` when provided. Drop supplementary groups/UID/GID correctly before invoking npx. Set child HOME, USER, LOGNAME and cwd to that user's values. Preserve the usable Node PATH.
- Do not create host mounts, host links, workspace modifications, runtime hooks, authentication, or agent CLI installations. Do not edit the existing Codex installer or its scenarios.
- Fail visibly for missing users, malformed option values, unavailable prerequisites, and failed npx commands. A source beginning with `-` must not become a CLI flag. Shell metacharacters must remain literal arguments.
- Fail the build when the CLI explicitly reports a nonzero `Failed to install N` summary, even if it exits zero. This is a reproduced skills@1.5.25 behavior when one agent destination cannot be created; preserve the CLI output and cover it with a regression test.
- Update the README, collection terminology, and test workflow to include the second Feature. Publishing already discovers every Feature under `src` and needs no change.
- Validate the real CLI in Docker, covering root and non-root users, both default agents, an overridden agent list, selected skill versus whole repository, repeat installation, and independent regular directories. Tests must not install skills into the developer's host home.

---

### Task 1: Implement and exercise the configurable Skills Feature

**Files:**

- Create: `src/skills/devcontainer-feature.json` (options and dependency)
- Create: `src/skills/install.sh` (Git prerequisite and runner entry point)
- Create: `src/skills/install.mjs` (option parsing, user resolution, npx invocation)
- Create: `test/skills/scenarios.json`, `test/skills/check.sh`, and matching executable scenario scripts (real remote distribution integration)
- Create: `test/skills/install.test.mjs` if useful for focused argument/error tests at the external process boundary
- Modify: `README.md`, `CONTEXT.md`, `.github/workflows/test.yaml`

**Interfaces:**

- Consumes Feature option environment variables `SOURCES`, `AGENTS`, `VERSION`, and standard Feature user variables.
- Produces copied skills in the selected agents' global directories owned by the configured container user; CLI source selection and agent destination rules remain owned by `skills`.

- [ ] **Step 1: Add executable scenarios and establish a failing baseline.**

Use a public source containing more than one skill for full-repository coverage and `vercel-labs/skills@find-skills` for specific-skill coverage. Use `mcr.microsoft.com/devcontainers/base:ubuntu` with `remoteUser: vscode` for the non-root case and `ubuntu:24.04` for root. A representative scenario configuration is:

```json
{
    "root": {
        "image": "ubuntu:24.04",
        "features": {
            "skills": {
                "sources": "vercel-labs/skills@find-skills",
                "version": "1.5.25"
            }
        }
    },
    "remote-user": {
        "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
        "remoteUser": "vscode",
        "features": {
            "skills": {
                "sources": "vercel-labs/skills@find-skills",
                "version": "1.5.25"
            }
        }
    },
    "claude-only": {
        "image": "ubuntu:24.04",
        "features": {
            "skills": {
                "sources": "vercel-labs/skills@find-skills",
                "agents": "claude-code",
                "version": "1.5.25"
            }
        }
    }
}
```

The checks inspect real `SKILL.md` contents, ownership, absence of symbolic links, absence of skills for an unselected agent, and success after repeat installation. Resolve actual paths from the installed CLI; skills@1.5.25 uses `~/.agents/skills` for Codex and `~/.claude/skills` for Claude Code. Use container-local fixture repositories for deterministic edge cases if needed, but retain at least one public remote fetch scenario.

Run:

```sh
devcontainer features test --project-folder . --features skills --skip-autogenerated
```

Expected initially: fails resolving the missing Feature. Save concise red/green evidence in the report.

- [ ] **Step 2: Add the Feature contract.**

```json
{
    "id": "skills",
    "name": "Agent Skills",
    "version": "1.0.0",
    "description": "Fetches and copies skills for configurable agents through the skills npm CLI.",
    "documentationURL": "https://github.com/kubamarchwicki/devcontainer-features#agent-skills",
    "licenseURL": "https://github.com/kubamarchwicki/devcontainer-features/blob/master/LICENSE",
    "options": {
        "sources": {
            "type": "string",
            "default": "",
            "description": "Comma- or newline-separated skills CLI sources, such as owner/repo or owner/repo@skill-name. Empty installs no skills."
        },
        "agents": {
            "type": "string",
            "default": "codex,claude-code",
            "description": "Comma- or whitespace-separated skills CLI agent IDs; use * for all supported agents."
        },
        "version": {
            "type": "string",
            "default": "latest",
            "description": "npm version or tag for the skills CLI."
        }
    },
    "dependsOn": {
        "ghcr.io/devcontainers/features/node:1": {}
    }
}
```

- [ ] **Step 3: Implement the installation boundary.**

Keep the shell entry point POSIX-compatible (`#!/bin/sh`, `set -eu`). Confirm `node` and `npx` exist. Install Git and CA certificates from apt-get, apk, or dnf only if Git is unavailable; emit an actionable error for an unsupported manager. Invoke the colocated runner using `node "$(dirname "$0")/install.mjs"`.

The runner uses `readFileSync` from `node:fs` and `spawnSync` from `node:child_process`. Parse sources with `split(/[,\n]/)` and agents with `split(/[,\s]+/)`, trim entries, and discard empty tokens. Resolve the configured user's passwd entry; reject missing users and a non-absolute home. Set supplementary groups with `process.initgroups(user, gid)`, then call `process.setgid(gid)` and `process.setuid(uid)` when starting as root. If already unprivileged, require the target UID to match.

Construct and execute each command with an argument array:

```js
const result = spawnSync('npx', [
  '--yes', '--package', `skills@${version}`, 'skills', 'add', source,
  '--global', '--copy', '--yes', '--agent', ...agents,
], {
  cwd: targetHome,
  env: {
    ...process.env,
    HOME: targetHome,
    USER: username,
    LOGNAME: username,
    npm_config_engine_strict: 'true',
    DISABLE_TELEMETRY: '1',
  },
  stdio: 'inherit',
});
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status || 1);
```

Use a top-level catch to print a concise `ERROR:` message and return exit status 1. Avoid a shared cross-Feature helper because each Feature is distributed independently. Set executable bits on shell files.

The subprocess example above illustrates argument and environment handling. Additionally, capture or stream and inspect its output with `NO_COLOR=1` to reject the upstream `Failed to install N` summary for nonzero N. Retain the CLI logs. A regular file at `~/.agents/skills` with a Codex-and-Claude installation reproduces the zero-exit partial failure in skills@1.5.25.

- [ ] **Step 4: Document the public interface and connect CI.**

Change the collection title and introduction to include both Features. Preserve the existing Codex documentation under a Codex-specific section. Add an Agent Skills section with this complete example:

```json
{
    "features": {
        "ghcr.io/kubamarchwicki/devcontainer-features/codex:1": {},
        "ghcr.io/kubamarchwicki/devcontainer-features/skills:1": {
            "sources": "vercel-labs/skills@find-skills,vercel-labs/agent-skills@web-design-guidelines",
            "agents": "codex,claude-code",
            "version": "1.5.25"
        }
    }
}
```

Document the three defaults, delimiters, whole-repository versus individual selection, rebuilds to reapply configuration, copy semantics, build-time remote-user installation, Node dependency and supported Linux bases, and the fact that private sources require credentials already available during the image build. Link to the official skills README for agent IDs and source formats. Explain that mounting over a target home/directory can hide build-time installations. State that source version pinning is separate from the CLI version, and pass pinned repository/tree URLs through unchanged.

In `CONTEXT.md`, replace the single-Feature definition with a two-Feature collection and distinguish Skills Feature from Codex Feature. Preserve ADR 0002's scope: the Codex Feature still does not manage Codex state. Add `skills` to `.github/workflows/test.yaml`'s existing feature matrix.

- [ ] **Step 5: Run focused and integration validation and commit.**

Run shell syntax checks on the new `.sh` files, `node --check src/skills/install.mjs`, JSON parsing for the manifest/scenarios, focused Node tests if added, and the complete Skills Feature scenario matrix. Run `git diff --check`. Save the exact commands and results in the task report. Fix any new failures before reporting completion; distinguish environmental download failures from implementation failures.

```sh
devcontainer features test --project-folder . --features skills --skip-autogenerated
git diff --check
git add src/skills test/skills README.md CONTEXT.md .github/workflows/test.yaml docs/plans/0003-skills-feature.md
git commit -m "feat: distribute agent skills through a devcontainer feature"
```

Expected: passing new scenarios and focused checks; one feature commit on `feat/skills`.
