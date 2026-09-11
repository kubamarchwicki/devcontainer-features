#!/bin/sh
set -eu

. ./check.sh
assert_skill root codex find-skills
assert_skill root claude-code find-skills
assert_independent_copies root find-skills
