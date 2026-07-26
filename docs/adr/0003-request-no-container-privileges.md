---
status: accepted
---

# Request no container privileges

The Codex Feature does not request privileged mode, Linux capabilities, security-option changes, mounts, or other weakening of the consumer's Container Security Policy. Codex must run within the container permissions selected by the consumer; compatibility problems with an inner sandbox remain explicit consumer decisions rather than reasons for the Feature to silently broaden access.
