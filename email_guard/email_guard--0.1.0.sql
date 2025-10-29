\echo Use "CREATE EXTENSION email_guard" to load this file.
\quit

-- email_guard v0.1.0
-- Signup email guard: Gmail normalization and disposable domain checks for Supabase Auth hooks

create table if not exists @extschema@.disposable_email_domains (
  domain text primary key,
  updated_at timestamptz not null default now(),
  constraint disposable_email_domains_domain_lowercase check (domain = lower(domain))
);

comment on table @extschema@.disposable_email_domains is 'Blocklist of disposable email domains used to prevent signups.';
comment on column @extschema@.disposable_email_domains.domain is 'Domain name (lowercase)';

-- Normalize email addresses (Gmail-specific rules)
-- For gmail.com/googlemail.com: remove dots and ignore +tag; normalize domain to gmail.com
create or replace function @extschema@.normalize_email(email text)
returns text
language plpgsql
immutable
as $$
declare
  local text;
  domain text;
begin
  if email is null then
    return null;
  end if;

  local := lower(split_part(email, '@', 1));
  domain := lower(split_part(email, '@', 2));

  if domain in ('gmail.com', 'googlemail.com') then
    local := split_part(local, '+', 1);
    local := replace(local, '.', '');
    domain := 'gmail.com';
  end if;

  return local || '@' || domain;
end;
$$;

comment on function @extschema@.normalize_email(text) is 'Normalize email; for Gmail removes dots and +suffix and normalizes domain to gmail.com.';

-- Predicate: does a domain (or any parent) appear in the disposable list?
create or replace function @extschema@.is_disposable_email_domain(in_domain text)
returns boolean
language plpgsql
stable
as $$
declare
  d text;
  pos int;
begin
  if in_domain is null or btrim(in_domain) = '' then
    return false;
  end if;
  d := lower(btrim(in_domain));

  loop
    if exists(select 1 from @extschema@.disposable_email_domains where domain = d) then
      return true;
    end if;
    pos := position('.' in d);
    if pos = 0 then
      return false;
    end if;
    d := substring(d from pos + 1);
  end loop;
end;
$$;

comment on function @extschema@.is_disposable_email_domain(text) is 'Returns true if the domain or any parent domain is in disposable_email_domains.';

-- Convenience: check by full email
create or replace function @extschema@.is_disposable_email(email text)
returns boolean
language sql
stable
as $$
  select @extschema@.is_disposable_email_domain(lower(split_part($1, '@', 2)));
$$;

comment on function @extschema@.is_disposable_email(text) is 'Returns true if email domain is disposable.';

-- Hook helper: block disposable domains and enforce single-account policy for Gmail
create or replace function @extschema@.hook_prevent_disposable_and_enforce_gmail_uniqueness(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  email text;
  domain text;
  normalized text;
  exists_user boolean;
begin
  email := event->'user'->>'email';

  -- Allow if no email (e.g., phone signups)
  if email is null or btrim(email) = '' then
    return '{}'::jsonb;
  end if;

  domain := lower(split_part(email, '@', 2));

  -- 1) Block disposable email domains
  if @extschema@.is_disposable_email_domain(domain) then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'message', 'Signups from disposable email domains are not allowed.',
        'http_code', 403
      )
    );
  end if;

  -- 2) Enforce Gmail single-account policy
  if domain in ('gmail.com', 'googlemail.com') then
    normalized := @extschema@.normalize_email(email);
    select exists(
      select 1
      from auth.users as u
      where @extschema@.normalize_email(u.email) = normalized
    ) into exists_user;

    if exists_user then
      return jsonb_build_object(
        'error', jsonb_build_object(
          'message', 'An account already exists for this Gmail address.',
          'http_code', 409
        )
      );
    end if;
  end if;

  return '{}'::jsonb;
end;
$$;

comment on function @extschema@.hook_prevent_disposable_and_enforce_gmail_uniqueness(jsonb) is 'Auth hook helper: blocks disposable domains and prevents duplicate Gmail signups using normalized email.';

-- Permissions
grant select on table @extschema@.disposable_email_domains to supabase_auth_admin;
revoke all on table @extschema@.disposable_email_domains from authenticated, anon, public;

grant execute on function @extschema@.normalize_email(text) to supabase_auth_admin;
grant execute on function @extschema@.is_disposable_email_domain(text) to supabase_auth_admin;
grant execute on function @extschema@.is_disposable_email(text) to supabase_auth_admin;
grant execute on function @extschema@.hook_prevent_disposable_and_enforce_gmail_uniqueness(jsonb) to supabase_auth_admin;

revoke execute on function @extschema@.normalize_email(text) from authenticated, anon, public;
revoke execute on function @extschema@.is_disposable_email_domain(text) from authenticated, anon, public;
revoke execute on function @extschema@.is_disposable_email(text) from authenticated, anon, public;
revoke execute on function @extschema@.hook_prevent_disposable_and_enforce_gmail_uniqueness(jsonb) from authenticated, anon, public;
