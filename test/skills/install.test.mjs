import assert from 'node:assert/strict';
import { chmodSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir, userInfo } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const runner = new URL('../../src/skills/install.mjs', import.meta.url);
const currentUser = userInfo();

function runRunner(options = {}) {
    const fixture = mkdtempSync(join(tmpdir(), 'skills-feature-test-'));
    const capture = join(fixture, 'capture.txt');
    const fakeNpx = join(fixture, 'npx');
    writeFileSync(fakeNpx, `#!/bin/sh\n{
    printf 'cwd=%s\\n' "$PWD"
    printf 'home=%s\\n' "$HOME"
    printf 'user=%s\\n' "$USER"
    printf 'logname=%s\\n' "$LOGNAME"
    printf 'engine=%s\\n' "$npm_config_engine_strict"
    printf 'telemetry=%s\\n' "$DISABLE_TELEMETRY"
    printf 'arg=%s\\n' "$@"
} >> "$SKILLS_TEST_CAPTURE"
printf '%s\\n' "$SKILLS_TEST_STDOUT"\n`);
    chmodSync(fakeNpx, 0o755);

    const result = spawnSync(process.execPath, [runner.pathname], {
        encoding: 'utf8',
        env: {
            ...process.env,
            PATH: `${fixture}:${process.env.PATH}`,
            _REMOTE_USER: currentUser.username,
            _REMOTE_USER_HOME: fixture,
            SOURCES: options.sources ?? '',
            AGENTS: options.agents ?? 'codex,claude-code',
            VERSION: options.version ?? '1.5.25',
            SKILLS_TEST_CAPTURE: capture,
            SKILLS_TEST_STDOUT: options.stdout ?? '',
        },
    });

    let captured = '';
    try {
        captured = readFileSync(capture, 'utf8');
    } catch (error) {
        if (error.code !== 'ENOENT') throw error;
    }
    return { ...result, captured, fixture };
}

test('forwards each parsed source and explicit agent as literal npx arguments', () => {
    const result = runRunner({
        sources: 'owner/one@alpha;still-literal,\nowner/two',
        agents: 'codex, claude-code',
        version: '1.5.25',
    });

    assert.equal(result.status, 0, result.stderr);
    const invocations = result.captured.trim().split(`cwd=${result.fixture}`).slice(1);
    assert.equal(invocations.length, 2);
    for (const invocation of invocations) {
        assert.match(invocation, /home=.*skills-feature-test-/);
        assert.match(invocation, /engine=true/);
        assert.match(invocation, /telemetry=1/);
        assert.match(invocation, /arg=--global\narg=--copy\narg=--yes\narg=--agent\narg=codex\narg=claude-code/);
    }
    assert.match(invocations[0], /arg=skills@1\.5\.25\narg=skills\narg=add\narg=owner\/one@alpha;still-literal/);
    assert.match(invocations[1], /arg=skills@1\.5\.25\narg=skills\narg=add\narg=owner\/two/);
});

test('does not invoke npx when sources is empty', () => {
    const result = runRunner({ sources: ' ,\n ' });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.captured, '');
});

test('rejects an empty agent list when sources are configured', () => {
    const result = runRunner({ sources: 'owner/repo', agents: ' , \t' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /^ERROR: .*agent/i);
    assert.equal(result.captured, '');
});

test('rejects a source that begins with a dash before invoking npx', () => {
    const result = runRunner({ sources: '--help' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /^ERROR: .*source/i);
    assert.equal(result.captured, '');
});

test('fails when the skills CLI reports an installation failure with exit status zero', () => {
    const result = runRunner({
        sources: 'owner/repo',
        stdout: 'Failed to install 1 skill',
    });
    assert.equal(result.status, 1);
    assert.match(result.stdout, /Failed to install 1 skill/);
    assert.match(result.stderr, /^ERROR: .*reported/i);
});
