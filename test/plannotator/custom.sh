#!/bin/sh
set -eu

. ./check.sh
grep -q 'PLANNOTATOR_PORT=20000' "${wrapper}"
grep -q 'PLANNOTATOR_URL_HOST=example.test' "${wrapper}"
! grep -q 'PLANNOTATOR_REMOTE' "${wrapper}"
