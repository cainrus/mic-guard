#!/usr/bin/env -S node --experimental-strip-types --disable-warning=ExperimentalWarning
// Builds native/mic-guard.swift when the source is newer than the binary, then
// runs it in the foreground: launchd's KeepAlive owns the process lifetime.
import { spawn, execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const SRC = fileURLToPath(new URL('../native/mic-guard.swift', import.meta.url));
const BIN = join(process.env.HOME ?? '', '.cache', 'mic-guard', 'mic-guard');

export function needsBuild(src: string, bin: string): boolean {
  return !existsSync(bin) || statSync(bin).mtimeMs < statSync(src).mtimeMs;
}

function build(): void {
  mkdirSync(dirname(BIN), { recursive: true, mode: 0o700 });
  execFileSync('/usr/bin/xcrun', ['swiftc', '-O', '-o', BIN, SRC], { stdio: 'inherit' });
  process.stdout.write(`${new Date().toISOString()} built ${BIN}\n`);
}

function main(): void {
  if (needsBuild(SRC, BIN)) build();
  const child = spawn(BIN, [], { stdio: 'inherit' });
  for (const signal of ['SIGTERM', 'SIGINT'] as const) {
    process.on(signal, () => child.kill(signal));
  }
  child.on('exit', (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
}

if (import.meta.url === `file://${process.argv[1]}`) main();
