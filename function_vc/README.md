# Function VC (Version Control)

Function VC is a set of functions that allow you to version control your Postgres functions in the database.

This is a Trusted language extension to allow for an easy install of the version control of Postgres functions that was published on this blog post: [Easy Deployment and Rollback of PostgreSQL Functions with Supabase](https://blog.mansueli.com/streamlining-postgresql-function-management-with-supabase).

## Installing FunctionVC

### Install Database.dev
<details>

<summary>(if you don't have it)</summary>
```
/*---------------------
---- install dbdev ----
----------------------
Requires:
  - pg_tle: https://github.com/aws/pg_tle
  - pgsql-http: https://github.com/pramsey/pgsql-http
*/
create extension if not exists http with schema extensions;
create extension if not exists pg_tle;
drop extension if exists "supabase-dbdev";
select pgtle.uninstall_extension_if_exists('supabase-dbdev');
select
    pgtle.install_extension(
        'supabase-dbdev',
        resp.contents ->> 'version',
        'PostgreSQL package manager',
        resp.contents ->> 'sql'
    )
from http(
    (
        'GET',
        'https://api.database.dev/rest/v1/'
        || 'package_versions?select=sql,version'
        || '&package_name=eq.supabase-dbdev'
        || '&order=version.desc'
        || '&limit=1',
        array[
            (
                'apiKey',
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJp'
                || 'c3MiOiJzdXBhYmFzZSIsInJlZiI6InhtdXB0cHBsZnZpaWZyY'
                || 'ndtbXR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAxMDczNzI'
                || 'sImV4cCI6MTk5NTY4MzM3Mn0.z2CN0mvO2No8wSi46Gw59DFGCTJ'
                || 'rzM0AQKsu_5k134s'
            )::http_header
        ],
        null,
        null
    )
) x,
lateral (
    select
        ((row_to_json(x) -> 'content') #>> '{}')::json -> 0
) resp(contents);
create extension "supabase-dbdev";
select dbdev.install('supabase-dbdev');
drop extension if exists "supabase-dbdev";
create extension "supabase-dbdev";
```
</details>

### Installing Function VC

```sql
select dbdev.install('mansueli-function_vc');
create extension "mansueli-function_vc"
    version '1.0.1';
```

## Creating a function:

```sql
SELECT create_function_from_source(
$$
-- Note that you can just paste the function below:
CREATE OR REPLACE FUNCTION public.convert_to_uuid(input_value text)
 RETURNS uuid
AS $function$
DECLARE
  hash_hex text;
BEGIN
  -- Return null if input_value is null or an empty string
  IF input_value IS NULL OR NULLIF(input_value, '') IS NULL THEN
    RETURN NULL;
  END IF;
  hash_hex := substring(encode(digest(input_value::bytea, 'sha512'), 'hex'), 1, 36);
  RETURN (left(hash_hex, 8) || '-' || right(hash_hex, 4) || '-4' || right(hash_hex, 3) || '-a' || right(hash_hex, 3) || '-' || right(hash_hex, 12))::uuid;
END;
$function$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
-- End of the function above
$$
);
```

Rolling back the latest version of a function:

```sql

SELECT rollback_function('convert_to_uuid');

```

Rolling back a specific version of a function:

```sql

SELECT rollback_function('convert_to_uuid', 2);

```

View the function history and versions

```sql

SELECT * from archive.function_history
  WHERE schema_name = 'public' 
  and function_name ='convert_to_uuid' ;

```

Check the current definition of a function

```sql

SELECT pg_get_functiondef((SELECT oid FROM pg_proc
  WHERE proname = 'convert_to_uuid'));

```

Storing all existing functions in the database:

```sql
SELECT archive.setup_function_history();
```

## Thanks to our contributors:
- [@imor](https://github.com/imor/)
- [@idea-garage](https://github.com/idea-garage/)
