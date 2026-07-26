---
status: accepted
---

# Bootstrap Node.js from distribution packages

The Codex Feature installs `nodejs` and `npm` from the container distribution's configured package repositories only when they are missing. It does not add NodeSource or another external repository, pin a Node.js major, require consumers to declare a separate Node Feature, or maintain an explicit distribution exclusion list; this keeps the one-line consumer experience while respecting the base image's package policy, at the cost that images providing a Node.js version incompatible with Codex will fail during installation.
