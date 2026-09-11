#!/bin/sh
set -eu

ensure_node_tools() {
    for command_name in node npx; do
        if ! command -v "${command_name}" >/dev/null 2>&1; then
            printf 'ERROR: Required command is unavailable: %s. Check the Node Feature installation.\n' \
                "${command_name}" >&2
            exit 1
        fi
    done
}

install_git() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive \
            apt-get install -y --no-install-recommends git ca-certificates
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache git ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git ca-certificates
    else
        printf '%s\n' \
            'ERROR: Git is missing, and no supported package manager (apt-get, apk, or dnf) was found.' >&2
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        printf '%s\n' 'ERROR: Failed to install Git.' >&2
        exit 1
    fi
}

ensure_node_tools

if ! command -v git >/dev/null 2>&1; then
    install_git
fi

node "$(dirname "$0")/install.mjs"
