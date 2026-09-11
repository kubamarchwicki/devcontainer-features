#!/bin/sh
set -eu

. ./check.sh
assert_skill vscode codex find-skills
assert_skill vscode claude-code find-skills
assert_independent_copies vscode find-skills
