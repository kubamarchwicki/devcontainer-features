# Codex Dev Container Feature

This context defines the language for a public collection that makes Codex available in development containers.

## Language

**Feature Collection**:
A publicly distributed collection containing exactly one Dev Container Feature for Codex.
_Avoid_: Feature repository, feature bundle

**Codex Feature**:
The Dev Container Feature through which a consumer adds the Codex CLI to a development container.
_Avoid_: Codex container, Codex image

**Consumer**:
A person or project that references the Codex Feature from a `devcontainer.json`.
_Avoid_: Client, user

**Feature Version**:
The semantic version of the Codex Feature artifact and its behavior.
_Avoid_: Package version, Codex version

**Codex Version**:
The version of the `@openai/codex` package installed by the Codex Feature.
_Avoid_: Feature version

**Codex State**:
Consumer-owned runtime data such as Codex authentication, configuration, sessions, skills, plugins, logs, and caches.
_Avoid_: Feature state, installation state

**Container Security Policy**:
The consumer-owned permissions and isolation settings within which Codex runs.
_Avoid_: Feature permissions, Codex privileges
