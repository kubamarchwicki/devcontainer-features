#!/bin/sh
set -eu

. ./check.sh
assert_skill root codex vercel-composition-patterns
assert_skill root codex web-design-guidelines
assert_skill_absent root claude-code vercel-composition-patterns
assert_skill_absent root claude-code web-design-guidelines
