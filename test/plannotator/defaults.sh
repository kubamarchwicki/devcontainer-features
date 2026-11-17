#!/bin/sh
set -eu

. ./check.sh
grep -q 'PLANNOTATOR_PORT=19432' "${wrapper}"
grep -q 'PLANNOTATOR_URL_HOST=localhost' "${wrapper}"
grep -q 'PLANNOTATOR_REMOTE=1' "${wrapper}"
grep -q 'PLANNOTATOR_AGENT_TERMINAL_REMOTE=1' "${wrapper}"
