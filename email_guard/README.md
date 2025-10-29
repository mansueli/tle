# email_guard

Trusted Language Extension (TLE) that guards Supabase Auth signups:
- Blocks disposable email domains.
- Normalizes Gmail addresses (remove dots and + tags) so each Gmail account can sign up only once.

Objects are created in the extension schema (`@extschema@`) so the package is relocatable.

## What’s inside

- Table: `@extschema@.disposable_email_domains(domain text primary key)`
- Function: `@extschema@.normalize_email(text)`
- Function: `@extschema@.is_disposable_email_domain(text)`
- Function: `@extschema@.is_disposable_email(text)`
- Hook helper: `@extschema@.hook_prevent_disposable_and_enforce_gmail_uniqueness(jsonb)`

Fresh installs and upgrades seed the full disposable-domain blocklist automatically; no extra seed scripts required.

## Install via database.dev (Supabase-friendly workflow)

You can publish this package as `mansueli@email_guard` and install it the same way you would install other dbdev TLEs.

### 1. Install dbdev & Supabase CLI (if needed)

- dbdev CLI: <https://supabase.github.io/dbdev/getting-started/>
- Supabase CLI: <https://supabase.com/docs/guides/cli>

Make sure your local project is connected to your Supabase database (`supabase link`). Supabase already has the `pg_tle` extension installed, which is the only prerequisite.

### 2. Generate a migration with dbdev

Use dbdev to pull version `0.2.0` (or newer) into your migrations folder. Example:

```bash
dbdev add \
  -o ./supabase/migrations/ \
  -v 0.2.0 \
  -s extensions \
  package \
  -n mansueli@email_guard
```

- `-s extensions` installs into the `extensions` schema (recommended on Supabase).
- Adjust the output folder if your project keeps migrations elsewhere.

### 3. Apply with Supabase CLI

Push the generated migration to your project database:

```bash
supabase db push
```

After the migration runs, the extension is installed and seeded in the target schema.

## Wire up the Supabase Auth hook

In the Supabase dashboard, add a **before-user-created** hook of type **Postgres Function** pointing to the schema and function you installed. For the example above (installed in `extensions`):

```
extensions.hook_prevent_disposable_and_enforce_gmail_uniqueness
```

Behavior:
- Disposable domains trigger a 403 with a helpful error message.
- Gmail/Googlemail addresses normalize to `gmail.com` with dots removed and `+tags` stripped; if a normalized Gmail already exists in `auth.users`, the hook raises a 409.
- Signups without an email (e.g., phone) are passed through unchanged.

## Keeping the blocklist current

This repo ships an automated workflow:
- Weekly job fetches the upstream disposable-email list.
- If there are changes, it bumps the minor version, creates the upgrade script, and commits both the new base version and control-file update.

To publish the updated version:

```bash
dbdev login        # paste your database.dev token
dbdev publish      # in the repo root or the email_guard folder
```

Upgrading your database to the new version pulls in the refreshed blocklist automatically.

## Handy queries

```sql
-- Check if an email domain is disposable
select extensions.is_disposable_email('user@mailinator.com');

-- Normalize a Gmail address
select extensions.normalize_email('e.xam.ple+promo@gmail.com');

-- Simulate hook behavior
select extensions.hook_prevent_disposable_and_enforce_gmail_uniqueness(
  '{"user": {"email": "e.xam.ple+1@gmail.com"}}'::jsonb
);
```

Replace `extensions` with the schema you chose if different.

## Notes

- The hook runs before the user is inserted, so only existing users are checked for Gmail duplicates.
- Domain matching walks up parent domains (`sub.mailinator.com` matches `mailinator.com`).
- The extension is relocatable; you can install it under any schema and reference it in the hook configuration.
