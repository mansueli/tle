# Function VC (Version Control)

Function VC is a set of functions that allow you to version control your Postgres functions in the database.

This is a Trusted language extension to allow for an easy install of the version control of Postgres functions that was published on this blog post: [Easy Deployment and Rollback of PostgreSQL Functions with Supabase](https://blog.mansueli.com/streamlining-postgresql-function-management-with-supabase).

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
