create function greet(name text default 'world')
  returns text language sql
as $$ select 'hello, ' || name; $$;