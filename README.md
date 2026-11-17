# Dev Container Features

A collection of Dev Container Features for agent tooling.

## Features

### Codex

Installs the OpenAI Codex CLI via npm. See the [Codex README](src/codex/README.md).

```json
{
    "features": {
        "ghcr.io/kubamarchwicki/devcontainer-features/codex:1": {}
    }
}
```

### Skills

Fetches agent skills into the container user's agent directories. See the [Skills README](src/skills/README.md).

```json
{
    "features": {
        "ghcr.io/kubamarchwicki/devcontainer-features/skills:1": {
            "sources": "vercel-labs/skills@find-skills,vercel-labs/agent-skills@web-design-guidelines",
            "agents": "codex,claude-code"
        }
    }
}
```

### Plannotator

Installs the Plannotator binary at build time. See the [Plannotator README](src/plannotator/README.md).

```json
{
    "features": {
        "ghcr.io/kubamarchwicki/devcontainer-features/plannotator:1": {
            "port": "${localEnv:DC_PLANNOTATOR_PORT:19432}",
            "urlHost": "${localEnv:DC_PLANNOTATOR_HOST:localhost}"
        }
    }
}
```

## Versioning

Each feature's `devcontainer-feature.json` holds a `major.minor.x` placeholder (e.g. `1.0.x`). Edit major and minor by hand when needed.

On every release (push to `master`), the workflow replaces `x` with the next patch number after the highest one already published to GHCR for that `major.minor`. The new version is used for publishing only and is not committed back. Pin a feature to `:1`, `:1.0`, or an exact `:1.0.3`.

## License

Licensed under the [MIT License](LICENSE).
