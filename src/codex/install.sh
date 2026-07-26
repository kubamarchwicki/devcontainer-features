#!/bin/sh
set -eu

VERSION="${VERSION:-latest}"

detect_package_manager() {
    for candidate in apt-get apk dnf; do
        if command -v "${candidate}" >/dev/null 2>&1; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done
    return 1
}

install_nodejs() {
    package_manager="$1"

    case "${package_manager}" in
        apt-get)
            apt-get update
            DEBIAN_FRONTEND=noninteractive \
                apt-get install -y --no-install-recommends nodejs npm
            ;;
        apk)
            apk add --no-cache nodejs npm
            ;;
        dnf)
            dnf install -y nodejs npm
            ;;
        *)
            printf 'ERROR: Unsupported package manager: %s\n' "${package_manager}" >&2
            exit 1
            ;;
    esac
}

ensure_nodejs() {
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        return 0
    fi

    if ! package_manager="$(detect_package_manager)"; then
        printf '%s\n' \
            'ERROR: Node.js and npm are missing, and no supported package manager was found.' >&2
        exit 1
    fi

    install_nodejs "${package_manager}"

    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        printf '%s\n' 'ERROR: Failed to install Node.js and npm.' >&2
        exit 1
    fi
}

ensure_nodejs
npm install --global --engine-strict "@openai/codex@${VERSION}"
codex --version
