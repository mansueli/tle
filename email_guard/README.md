# email_guard

Helper functions for Supabase Auth “before-user-created” hook:
- Block signups from disposable email domains
- Enforce single-account policy for Gmail by normalizing addresses (remove dots and +tag)

## What it provides

- Table: `public.disposable_email_domains(domain text primary key)`
- Function: `public.normalize_email(email text) returns text`
- Function: `public.is_disposable_email_domain(domain text) returns boolean`
- Function: `public.is_disposable_email(email text) returns boolean`
- Hook helper: `public.hook_prevent_disposable_and_enforce_gmail_uniqueness(event jsonb) returns jsonb`

Normalization details:
- For `gmail.com` and `googlemail.com`, dots in the local part are removed, anything after `+` is stripped, and the domain is normalized to `gmail.com`.
- For all other domains, the email is lowercased only.

## Install (database.dev)

This package is formatted for database.dev. After publishing from this repo (see below), you can add it to a database:

```sql
create extension email_guard
  schema email_guard
  version 'LATEST';
```

The weekly workflow bumps minor versions when the upstream blocklist changes and embeds the updated data into the extension so a fresh install includes the latest domains. If you prefer, you can also seed manually:

```sql
-- Optional: manual seeding for the default public schema
--   Run email_guard/seed/disposable_email_domains.sql
-- If you installed in a non-public schema, adapt the table reference accordingly.
```

## Configure the Auth hook

In the Supabase dashboard, go to Auth → Hooks and create a “before-user-created” hook of type “Postgres Function”, pointing to:

```
<your_schema>.hook_prevent_disposable_and_enforce_gmail_uniqueness
```

This function expects the event payload described in the Supabase docs and will:
- Reject disposable email domains with HTTP 403 and a clear message.
- For Gmail addresses, reject signups that normalize to an existing account with HTTP 409.

## Keeping the blocklist fresh

This repo includes a GitHub Action that runs weekly to:
- Regenerate `email_guard/seed/disposable_email_domains.sql` from the upstream list
- If the list changed, bump the extension minor version and generate:
  - `email_guard/email_guard--<prev>--<next>.sql` (upgrade: truncates and inserts new data)
  - `email_guard/email_guard--<next>.sql` (base: includes DDL and the latest data)
- Source: https://github.com/disposable-email-domains/disposable-email-domains/blob/main/disposable_email_blocklist.conf

If you want to refresh it manually, run:

```sh
node scripts/update_disposable_domains.js
```

Then apply the updated seed SQL to your database if you want to refresh immediately without upgrading the extension. Otherwise, upgrading the extension to the next version will perform the data refresh.

## Publish to database.dev

1. Authenticate: `dbdev login` (use a token from database.dev)
2. From the repo root (or package folder), run: `dbdev publish`
3. New versions are published after the weekly job bumps versions when the blocklist changes.

Notes:
- The extension is relocatable and uses `@extschema@` placeholders internally.
- Upgrade and base SQL embed data using `insert into @extschema@.disposable_email_domains...`.

## Examples

- Check if an email is disposable:

```sql
select public.is_disposable_email('user@mailinator.com'); -- true
```

- See the normalized Gmail form:

```sql
select public.normalize_email('e.xam.ple+promo@gmail.com'); -- example@gmail.com
```

- Use in the before-user-created hook:

```sql
select public.hook_prevent_disposable_and_enforce_gmail_uniqueness(
  '{"user": {"email": "e.xam.ple+1@gmail.com"}}'::jsonb
);
```

## Notes

- The hook runs before insertion; the new user is not yet present in `auth.users`, but existing users are. The Gmail uniqueness check compares the normalized form across existing users.
- The domain check treats parent domains as matches (e.g., `sub.mailinator.com` matches `mailinator.com`).
