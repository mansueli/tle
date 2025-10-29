#!/usr/bin/env node
/**
 * Bumps the minor version of the email_guard extension when the blocklist changes,
 * generating a new base version file and an upgrade file that embed the latest data.
 *
 * Versioning strategy: a.b.c -> a.(b+1).0
 */
import { readdir, readFile, writeFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const SOURCE_URL = 'https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const EXT_DIR = path.join(ROOT, 'email_guard');
const CONTROL_PATH = path.join(EXT_DIR, 'email_guard.control');

function parseDefaultVersion(controlText) {
  const m = controlText.match(/default_version\s*=\s*'?([0-9]+\.[0-9]+\.[0-9]+)'?/);
  if (!m) throw new Error('Could not parse default_version from control file');
  return m[1];
}

function bumpMinor(v) {
  const [maj, min] = v.split('.').map(n => parseInt(n, 10));
  return `${maj}.${min + 1}.0`;
}

async function fetchDomains() {
  const res = await fetch(SOURCE_URL);
  if (!res.ok) throw new Error(`Failed to fetch blocklist: ${res.status}`);
  const text = await res.text();
  const lines = text.split(/\r?\n/)
    .map(l => l.trim())
    .filter(l => l && !l.startsWith('#'));
  return Array.from(new Set(lines.map(l => l.toLowerCase()))).sort();
}

function buildInsertSQL(domains) {
  if (domains.length === 0) return '-- No domains to insert\n';
  const values = domains.map(d => `('${d.replace(/'/g, "''")}')`).join(',\n');
  return `insert into @extschema@.disposable_email_domains(domain) values\n${values};\n`;
}

async function findLatestBaseFile() {
  const files = await readdir(EXT_DIR);
  const baseFiles = files.filter(f => /email_guard--[0-9]+\.[0-9]+\.[0-9]+\.sql$/.test(f));
  if (baseFiles.length === 0) throw new Error('No base SQL found');
  const versions = baseFiles.map(f => f.match(/email_guard--([0-9]+\.[0-9]+\.[0-9]+)\.sql$/)[1]);
  versions.sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  const latest = versions[versions.length - 1];
  return { version: latest, file: path.join(EXT_DIR, `email_guard--${latest}.sql`) };
}

async function main() {
  const controlText = await readFile(CONTROL_PATH, 'utf8');
  const currentVersion = parseDefaultVersion(controlText);
  const nextVersion = bumpMinor(currentVersion);

  const domains = await fetchDomains();
  const baseInsert = buildInsertSQL(domains);

  const upgradePath = path.join(EXT_DIR, `email_guard--${currentVersion}--${nextVersion}.sql`);
  const upgradeSQL = `-- Auto-generated upgrade to embed latest disposable domain data\n-- Source: ${SOURCE_URL}\n\ntruncate table @extschema@.disposable_email_domains;\n${baseInsert}`;
  await writeFile(upgradePath, upgradeSQL, 'utf8');

  const { file: latestBaseFile } = await findLatestBaseFile();
  const latestBaseSQL = await readFile(latestBaseFile, 'utf8');
  const nextBasePath = path.join(EXT_DIR, `email_guard--${nextVersion}.sql`);
  const nextBaseSQL = `${latestBaseSQL}\n\n-- Seed disposable email domains (auto-generated)\n-- Source: ${SOURCE_URL}\n${baseInsert}`;
  await writeFile(nextBasePath, nextBaseSQL, 'utf8');

  const newControl = controlText.replace(/default_version\s*=\s*'?([0-9]+\.[0-9]+\.[0-9]+)'?/, `default_version = ${nextVersion}`);
  await writeFile(CONTROL_PATH, newControl, 'utf8');

  console.log(`Bumped email_guard from ${currentVersion} to ${nextVersion}`);
  console.log(`Wrote:\n - ${path.relative(ROOT, upgradePath)}\n - ${path.relative(ROOT, nextBasePath)}\n - updated ${path.relative(ROOT, CONTROL_PATH)}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
