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
const README_PATH = path.join(EXT_DIR, 'README.md');

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

function escapeDomain(domain) {
  return domain.replace(/'/g, "''");
}

function formatValues(domains) {
  return domains.map(d => `('${escapeDomain(d)}')`).join(',\n');
}

function buildFullInsertSQL(domains) {
  if (domains.length === 0) {
    return '-- No domains to insert\n';
  }
  return `insert into @extschema@.disposable_email_domains(domain) values\n${formatValues(domains)};\n`;
}

function buildUpsertSQL(domains) {
  if (domains.length === 0) {
    return '';
  }
  return `insert into @extschema@.disposable_email_domains(domain) values\n${formatValues(domains)}\nON CONFLICT (domain) DO NOTHING;\n`;
}

function buildDeleteSQL(domains) {
  if (domains.length === 0) {
    return '';
  }
  const list = domains.map(d => `  '${escapeDomain(d)}'`).join(',\n');
  return `delete from @extschema@.disposable_email_domains\nwhere domain in (\n${list}\n);\n`;
}

function stripExistingSeed(sql) {
  const marker = '-- Seed disposable email domains (auto-generated)';
  const idx = sql.indexOf(marker);
  if (idx === -1) {
    return sql.replace(/\s+$/u, '');
  }
  return sql.slice(0, idx).replace(/\s+$/u, '');
}

function extractSeedDomains(sql) {
  const marker = 'insert into @extschema@.disposable_email_domains(domain) values';
  const start = sql.indexOf(marker);
  if (start === -1) {
    return [];
  }
  const end = sql.indexOf(';', start);
  if (end === -1) {
    throw new Error('Could not locate the end of the seed insert statement');
  }
  const fragment = sql.slice(start, end);
  const matches = [...fragment.matchAll(/\('([^']+)'\)/g)];
  return matches.map((m) => m[1]);
}

function updateVersionComment(sql, version) {
  const re = /(\s*--\s*email_guard v)(\d+\.\d+\.\d+)/;
  if (!re.test(sql)) {
    return sql;
  }
  return sql.replace(re, `$1${version}`);
}

async function updateReadmeVersion(currentVersion, nextVersion) {
  let readme;
  try {
    readme = await readFile(README_PATH, 'utf8');
  } catch (err) {
    if (err.code === 'ENOENT') {
      return false;
    }
    throw err;
  }

  const replaced = readme
    .replaceAll(`\`${currentVersion}\``, `\`${nextVersion}\``)
    .replaceAll(`-v ${currentVersion}`, `-v ${nextVersion}`);

  if (replaced !== readme) {
    await writeFile(README_PATH, replaced, 'utf8');
    return true;
  }

  return false;
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

  const domains = await fetchDomains();

  const { file: latestBaseFile } = await findLatestBaseFile();
  const latestBaseSQL = await readFile(latestBaseFile, 'utf8');
  const previousDomains = extractSeedDomains(latestBaseSQL);

  const newSet = new Set(domains);
  const prevSet = new Set(previousDomains);

  const additions = domains.filter((d) => !prevSet.has(d));
  const removals = previousDomains.filter((d) => !newSet.has(d));

  if (additions.length === 0 && removals.length === 0) {
    console.log('Blocklist unchanged; nothing to do.');
    return;
  }

  const nextVersion = bumpMinor(currentVersion);

  const upgradeStatements = [`-- Auto-generated upgrade to embed latest disposable domain data`, `-- Source: ${SOURCE_URL}`];
  if (removals.length) {
    upgradeStatements.push(buildDeleteSQL(removals).trimEnd());
  }
  if (additions.length) {
    upgradeStatements.push(buildUpsertSQL(additions).trimEnd());
  }
  const upgradeSQL = `${upgradeStatements.join('\n\n')}\n`;
  const upgradePath = path.join(EXT_DIR, `email_guard--${currentVersion}--${nextVersion}.sql`);
  await writeFile(upgradePath, upgradeSQL, 'utf8');

  const strippedBase = updateVersionComment(stripExistingSeed(latestBaseSQL), nextVersion);
  const nextBasePath = path.join(EXT_DIR, `email_guard--${nextVersion}.sql`);
  const baseInsert = buildFullInsertSQL(domains);
  const nextBaseSQL = `${strippedBase}\n\n-- Seed disposable email domains (auto-generated)\n-- Source: ${SOURCE_URL}\n${baseInsert}`;
  await writeFile(nextBasePath, nextBaseSQL, 'utf8');

  const newControl = controlText.replace(/default_version\s*=\s*'?([0-9]+\.[0-9]+\.[0-9]+)'?/, `default_version = ${nextVersion}`);
  await writeFile(CONTROL_PATH, newControl, 'utf8');

  const readmeUpdated = await updateReadmeVersion(currentVersion, nextVersion);

  console.log(`Bumped email_guard from ${currentVersion} to ${nextVersion}`);
  console.log(`Wrote:\n - ${path.relative(ROOT, upgradePath)}\n - ${path.relative(ROOT, nextBasePath)}\n - updated ${path.relative(ROOT, CONTROL_PATH)}`);
  if (readmeUpdated) {
    console.log(` - updated ${path.relative(ROOT, README_PATH)}`);
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
