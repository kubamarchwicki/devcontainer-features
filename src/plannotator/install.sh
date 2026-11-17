#!/bin/sh
set -eu

VERSION="${VERSION:-latest}"
REMOTE="${REMOTE-1}"
AGENTTERMINALREMOTE="${AGENTTERMINALREMOTE-1}"
PORT="${PORT-19432}"
URLHOST="${URLHOST-localhost}"

LIB_DIR=/usr/local/lib/plannotator
BIN_DIR=/usr/local/bin

install_prerequisites() {
    missing=""
    for tool in curl tar xz bash; do
        command -v "${tool}" >/dev/null 2>&1 || missing="${missing} ${tool}"
    done
    [ -n "${missing}" ] || return 0

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive \
            apt-get install -y --no-install-recommends curl ca-certificates tar xz-utils bash
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl ca-certificates tar xz bash
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl ca-certificates tar xz bash
    else
        printf 'ERROR: Missing%s, and no supported package manager (apt-get, apk, or dnf) was found.\n' \
            "${missing}" >&2
        exit 1
    fi
}

# Writes `: "${NAME:=value}"`-style defaults so runtime values win.
emit_default() {
    name="$1"
    value="$2"
    [ -n "${value}" ] || return 0
    case "${value}" in
        *[!A-Za-z0-9._:/@-]*)
            printf 'ERROR: Unsupported characters in value for %s\n' "${name}" >&2
            exit 1
            ;;
    esac
    printf 'if [ -z "${%s+x}" ]; then %s=%s; export %s; fi\n' "${name}" "${name}" "${value}" "${name}"
}

install_prerequisites

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${work_dir}/home"

# Binary-only install into a throwaway HOME: no per-user state is written.
installer_args="--minimal --non-interactive"
if [ "${VERSION}" != "latest" ]; then
    installer_args="${installer_args} --version ${VERSION}"
fi
curl -fsSL https://plannotator.ai/install.sh -o "${work_dir}/install.sh"
# shellcheck disable=SC2086
HOME="${work_dir}/home" bash "${work_dir}/install.sh" ${installer_args}

mkdir -p "${LIB_DIR}"
install -m 0755 "${work_dir}/home/.local/bin/plannotator" "${LIB_DIR}/plannotator"

# The wrapper applies the configured defaults for every caller (shells, agent
# hooks, non-login processes); values already in the environment take precedence.
{
    printf '#!/bin/sh\n'
    emit_default PLANNOTATOR_REMOTE "${REMOTE}"
    emit_default PLANNOTATOR_AGENT_TERMINAL_REMOTE "${AGENTTERMINALREMOTE}"
    emit_default PLANNOTATOR_PORT "${PORT}"
    emit_default PLANNOTATOR_URL_HOST "${URLHOST}"
    printf 'exec %s/plannotator "$@"\n' "${LIB_DIR}"
} > "${BIN_DIR}/plannotator"
chmod 0755 "${BIN_DIR}/plannotator"

command -v plannotator >/dev/null 2>&1
