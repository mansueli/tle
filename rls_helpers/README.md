## RLS Helpers

This is an extension with convenience functions to help test and simulate RLS policies within the database.

You can use use it to get RLS context within direct database access or with Supavisor:

## Usage

You can simulate log in as an user with the following:

### Login as user:

```sql
BEGIN;
CALL auth.login_as_user('rodrigo@contoso.com');
SELECT * FROM profiles;
COMMIT;
```

### Anon access:
```sql
BEGIN;
CALL auth.login_as_anon();
SELECT * FROM profiles;
COMMIT;
```


### Logout:

```sql
BEGIN;
CALL auth.login_as_user('rodrigo@contoso.com');
SELECT * FROM profiles;
CALL auth.logout();
-- You are back to postgres role here:
SELECT * FROM profiles;
COMMIT;
```