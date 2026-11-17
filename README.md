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

## License

Licensed under the [MIT License](LICENSE).
