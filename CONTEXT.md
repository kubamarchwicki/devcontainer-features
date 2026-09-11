# Codex and Agent Skills Dev Container Features

This context defines the language for a public collection that makes Codex and reusable agent skills available in development containers.

## Language

**Feature Collection**:
A publicly distributed collection containing the Codex Feature and the Agent Skills Feature.
_Avoid_: Feature repository, feature bundle

**Codex Feature**:
The Dev Container Feature through which a consumer adds the Codex CLI to a development container.
_Avoid_: Codex container, Codex image

**Agent Skills Feature**:
The Dev Container Feature through which a consumer fetches skills with the `skills` CLI and copies them into configurable agents' global directories.
_Avoid_: Codex skills manager, host skills bridge

**Consumer**:
A person or project that references one or both Features from a `devcontainer.json`.
_Avoid_: Client, user

**Feature Version**:
The semantic version of a Feature artifact and its behavior.
_Avoid_: Package version, Codex version

**Codex Version**:
The version of the `@openai/codex` package installed by the Codex Feature.
_Avoid_: Feature version

**Skills CLI Version**:
The npm version or tag of the `skills` package used by the Agent Skills Feature.
_Avoid_: Feature version, skill source version

**Skill Source**:
A source specification passed intact to the `skills` CLI, selecting a whole repository or an individual skill and optionally pinning a repository revision.
_Avoid_: Skills CLI version

**Codex State**:
Consumer-owned runtime data such as Codex authentication, configuration, sessions, skills, plugins, logs, and caches.
_Avoid_: Feature state, installation state

ADR 0002 applies to the Codex Feature: it installs only the Codex CLI and does not manage Codex State. The separate Agent Skills Feature installs only explicitly configured skills at image build time; it does not change the Codex Feature's scope.

**Container Security Policy**:
The consumer-owned permissions and isolation settings within which Codex runs.
_Avoid_: Feature permissions, Codex privileges
