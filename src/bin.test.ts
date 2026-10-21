import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, utimesSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { needsBuild } from './bin.ts';

test('needsBuild: missing binary, stale binary, fresh binary', () => {
  const dir = mkdtempSync(join(tmpdir(), 'mic-guard-'));
  const src = join(dir, 'a.swift');
  const bin = join(dir, 'a');
  writeFileSync(src, '');
  assert.equal(needsBuild(src, bin), true);
  writeFileSync(bin, '');
  utimesSync(bin, 1000, 1000);
  assert.equal(needsBuild(src, bin), true);
  utimesSync(bin, Date.now() / 1000 + 60, Date.now() / 1000 + 60);
  assert.equal(needsBuild(src, bin), false);
});
