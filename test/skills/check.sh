#!/bin/sh
set -eu

home_for() {
    getent passwd "$1" | cut -d: -f6
}

agent_skills_dir() {
    user_home="$1"
    agent="$2"

    case "${agent}" in
        codex) printf '%s\n' "${user_home}/.agents/skills" ;;
        claude-code) printf '%s\n' "${user_home}/.claude/skills" ;;
        *)
            printf 'Unknown test agent: %s\n' "${agent}" >&2
            exit 1
            ;;
    esac
}

assert_skill() {
    username="$1"
    agent="$2"
    skill_name="$3"
    user_home="$(home_for "${username}")"
    skills_dir="$(agent_skills_dir "${user_home}" "${agent}")"
    skill_dir="${skills_dir}/${skill_name}"
    skill_file="${skill_dir}/SKILL.md"

    test -d "${skill_dir}"
    test ! -L "${skills_dir}"
    test ! -L "${skill_dir}"
    test -f "${skill_file}"
    test ! -L "${skill_file}"
    grep -Eq "^name:[[:space:]]*${skill_name}[[:space:]]*$" "${skill_file}"

    if find "${skill_dir}" ! -user "${username}" -print -quit | grep -q .; then
        printf 'Expected every file under %s to be owned by %s\n' "${skill_dir}" "${username}" >&2
        exit 1
    fi
}

assert_skill_absent() {
    username="$1"
    agent="$2"
    skill_name="$3"
    user_home="$(home_for "${username}")"
    skills_dir="$(agent_skills_dir "${user_home}" "${agent}")"

    test ! -e "${skills_dir}/${skill_name}"
}

assert_independent_copies() {
    username="$1"
    skill_name="$2"
    user_home="$(home_for "${username}")"
    codex_file="$(agent_skills_dir "${user_home}" codex)/${skill_name}/SKILL.md"
    claude_file="$(agent_skills_dir "${user_home}" claude-code)/${skill_name}/SKILL.md"

    if [ "${codex_file}" -ef "${claude_file}" ]; then
        printf 'Expected independent copies, but %s and %s are the same file\n' \
            "${codex_file}" "${claude_file}" >&2
        exit 1
    fi
}

assert_no_default_skills() {
    username="$1"
    user_home="$(home_for "${username}")"

    test ! -e "$(agent_skills_dir "${user_home}" codex)"
    test ! -e "$(agent_skills_dir "${user_home}" claude-code)"
}
