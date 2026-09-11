#!/bin/sh
set -eu

. ./check.sh
assert_skill root claude-code find-skills
assert_skill_absent root codex find-skills
