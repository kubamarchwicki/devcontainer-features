#!/bin/sh
set -eu

for command_name in node npm codex; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Expected command was not installed: %s\n' "${command_name}" >&2
        exit 1
    fi
done

expected_version="${1:-}"
version_output="$(codex --version)"
printf '%s\n' "${version_output}"

if [ -n "${expected_version}" ]; then
    case "${version_output}" in
        *"${expected_version}"*) ;;
        *)
            printf 'Expected Codex version %s, got: %s\n' "${expected_version}" "${version_output}" >&2
            exit 1
            ;;
    esac
fi
