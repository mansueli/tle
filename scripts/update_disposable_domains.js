#!/usr/bin/env node
/**
 * Fetches the disposable email domain blocklist and generates a seed SQL file.
 */
import { mkdir, writeFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const SOURCE_URL = 'https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_PATH = path.join(__dirname, '..', 'email_guard', 'seed', 'disposable_email_domains.sql');

async function main() {
  const res = await fetch(SOURCE_URL);
  if (!res.ok) {
    throw new Error(`Failed to fetch blocklist: ${res.status} ${res.statusText}`);
  }
  const text = await res.text();
  const lines = text.split(/\r?\n/)
    .map(l => l.trim())
    .filter(l => l.length > 0 && !l.startsWith('#'));

  // Deduplicate and sort
  const domains = Array.from(new Set(lines.map(l => l.toLowerCase()))).sort();

  const header = `-- Auto-generated file. DO NOT EDIT.
-- Source: ${SOURCE_URL}
-- Generated: ${new Date().toISOString()}
-- This script truncates and repopulates public.disposable_email_domains.

begin;\n`;

  const truncate = 'truncate table public.disposable_email_domains;\n';

  const values = domains.map(d => `('${d.replace(/'/g, "''")}')`).join(',\n');
  const insert = domains.length > 0
    ? `insert into public.disposable_email_domains(domain) values\n${values};\n`
    : '-- No domains found to insert\n';

  const footer = 'commit;\n';

  const content = header + truncate + insert + footer;

  await mkdir(path.dirname(OUT_PATH), { recursive: true });
  await writeFile(OUT_PATH, content, 'utf8');
  console.log(`Wrote ${domains.length} domains to ${OUT_PATH}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
