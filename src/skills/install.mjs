import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { isAbsolute } from 'node:path';

function tokens(value, separator) {
    return value.split(separator).map((entry) => entry.trim()).filter(Boolean);
}

function configuredUser() {
    return process.env._REMOTE_USER?.trim()
        || process.env._CONTAINER_USER?.trim()
        || 'root';
}

function passwdEntry(configuredUser) {
    const configuredUid = /^\d+$/.test(configuredUser) ? BigInt(configuredUser) : null;
    const entry = readFileSync('/etc/passwd', 'utf8')
        .split('\n')
        .find((line) => {
            const fields = line.split(':');
            if (configuredUid !== null) {
                return /^\d+$/.test(fields[2] ?? '') && BigInt(fields[2]) === configuredUid;
            }
            return fields[0] === configuredUser;
        });

    if (!entry) {
        throw new Error(`Configured container user does not exist: ${configuredUser}`);
    }

    const fields = entry.split(':');
    const username = fields[0];
    const uid = Number(fields[2]);
    const gid = Number(fields[3]);
    const passwdHome = fields[5];
    if (!Number.isInteger(uid) || !Number.isInteger(gid)) {
        throw new Error(`Configured container user has an invalid passwd entry: ${username}`);
    }

    const targetHome = process.env._REMOTE_USER_HOME?.trim() || passwdHome;
    if (!targetHome || !isAbsolute(targetHome)) {
        throw new Error(`Configured container user has a non-absolute home: ${username}`);
    }

    return { username, uid, gid, targetHome };
}

function assumeIdentity({ username, uid, gid }) {
    if (process.getuid() === 0) {
        process.initgroups(username, gid);
        process.setgid(gid);
        process.setuid(uid);
        return;
    }

    if (process.getuid() !== uid) {
        throw new Error(
            `Cannot install for ${username} (UID ${uid}) while running as UID ${process.getuid()}`,
        );
    }
}

function writeChildOutput(result) {
    if (result.stdout) process.stdout.write(result.stdout);
    if (result.stderr) process.stderr.write(result.stderr);
}

function reportsInstallFailures(output) {
    return Array.from(output.matchAll(/\bFailed to install\s+(\d+)\b/gi))
        .some((match) => BigInt(match[1]) > 0n);
}

function run() {
    const sources = tokens(process.env.SOURCES ?? '', /[,\n]/);
    if (sources.length === 0) return 0;

    const agents = tokens(process.env.AGENTS ?? 'codex,claude-code', /[,\s]+/);
    if (agents.length === 0) {
        throw new Error('At least one agent is required when sources are configured.');
    }
    if (agents.some((agent) => agent.startsWith('-'))) {
        throw new Error('Agent IDs must not begin with a dash.');
    }
    if (sources.some((source) => source.startsWith('-'))) {
        throw new Error('Skill sources must not begin with a dash.');
    }

    const version = (process.env.VERSION ?? 'latest').trim();
    if (!version) throw new Error('The skills CLI version must not be empty.');

    const identity = passwdEntry(configuredUser());
    assumeIdentity(identity);

    for (const source of sources) {
        const result = spawnSync('npx', [
            '--yes', '--package', `skills@${version}`, 'skills', 'add', source,
            '--global', '--copy', '--yes', '--agent', ...agents,
        ], {
            cwd: identity.targetHome,
            env: {
                ...process.env,
                HOME: identity.targetHome,
                USER: identity.username,
                LOGNAME: identity.username,
                npm_config_engine_strict: 'true',
                DISABLE_TELEMETRY: '1',
                NO_COLOR: '1',
            },
            encoding: 'utf8',
            maxBuffer: 10 * 1024 * 1024,
        });

        writeChildOutput(result);
        if (result.error) throw result.error;
        if (result.status !== 0) return result.status || 1;
        if (reportsInstallFailures(`${result.stdout ?? ''}\n${result.stderr ?? ''}`)) {
            throw new Error('The skills CLI reported one or more installation failures.');
        }
    }

    return 0;
}

try {
    process.exitCode = run();
} catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`ERROR: ${message}`);
    process.exitCode = 1;
}
