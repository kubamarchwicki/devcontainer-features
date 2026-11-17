#!/bin/sh
set -eu

wrapper="$(command -v plannotator)"
test -x "${wrapper}"
test -x /usr/local/lib/plannotator/plannotator

# The wrapper must carry the configured defaults and let the environment override them.
grep -q 'PLANNOTATOR_PORT' "${wrapper}"
