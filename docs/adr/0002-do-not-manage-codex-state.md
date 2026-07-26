---
status: accepted
---

# Do not manage Codex state

The Codex Feature installs only the Codex CLI and does not mount, copy, initialize, persist, change ownership of, or otherwise manage `CODEX_HOME`, `~/.codex`, authentication, configuration, or other Codex State. Consumers retain explicit control over any state sharing or persistence, avoiding the credential exposure and host mutation risks of an implicit writable host mount at the cost of requiring consumers to configure persistence themselves when desired.
