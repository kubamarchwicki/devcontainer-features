#!/bin/sh
set -eu

VERSION="${VERSION:-latest}"

ensure_nodejs() {
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' \
            'ERROR: Node.js and npm are missing, and apt-get is not available.' >&2
        exit 1
    fi

    apt-get update
    DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends nodejs npm

    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        printf '%s\n' 'ERROR: Failed to install Node.js and npm.' >&2
        exit 1
    fi
}

ensure_nodejs
npm install --global --engine-strict "@openai/codex@${VERSION}"
codex --version
