# BrainFuck Trusted Language Extension (TLE) for PostgreSQL

## Overview
The **BrainFuck TLE** is a Trusted Language Extension (TLE) for PostgreSQL that allows users to execute BrainFuck programs directly within their database. This extension provides a fun and unconventional way to integrate esoteric programming into PostgreSQL.

## Features
- Execute BrainFuck programs within SQL queries
- Supports standard BrainFuck operations (`+`, `-`, `<`, `>`, `[`, `]`, `,`, `.`)
- Sandbox execution within the PostgreSQL environment
- Compatible with Supabase and other PostgreSQL deployments with TLE support

## Prerequisites
Before installing the BrainFuck TLE, ensure that your PostgreSQL instance meets the following requirements:
- PostgreSQL 15+ with Trusted Language Extensions (TLE) enabled
- `pg_tle` extension installed
- `dbdev` extension installed
-  `plv8` extension installed

## Installation
### Step 1: Install TLE Dependencies
If you haven't already installed the necessary TLE components, run the following SQL commands:

```sql
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_tle;
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
            ('apiKey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtdXB0cHBsZnZpaWZyYndtbXR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAxMDczNzIsImV4cCI6MTk5NTY4MzM3Mn0.z2CN0mvO2No8wSi46Gw59DFGCTJrzM0AQKsu_5k134s')::http_header
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

### Step 2: Install BrainFuck TLE
Once TLE is set up, install the BrainFuck extension:

```sql
SELECT dbdev.install('mansueli@brainfuck');
CREATE EXTENSION "mansueli@brainfuck"
    SCHEMA public -- You can change it here to something else
    VERSION '4.2.0';
```

## Usage
### Running a BrainFuck Program in PostgreSQL
You can execute a BrainFuck program using the provided functions:

```sql
SELECT brainfuck(',[.[-],]');
```

### Example: Hello World
To print "Hello World" using BrainFuck within PostgreSQL:

```sql
SELECT brainfuck('++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>.<<+++++++++++++++.>.+++.------.--------.>.>+.','');
```

## Uninstallation
If you need to remove the BrainFuck TLE, use the following command:

```sql
DROP EXTENSION "mansueli@brainfuck";
```

## Notes & Warnings
- This extension is experimental and should be used with caution in production environments.
- BrainFuck programs can be slow due to their esoteric nature.
- Running complex BrainFuck scripts may impact database performance.

## License
This project is licensed under the Apache-2.0 License. See the [LICENSE](https://github.com/mansueli/tle/tree/master?tab=Apache-2.0-1-ov-file#readme) file for details.

## Contributing
Contributions, issues, and feature requests are welcome! Feel free to open a PR or issue on [GitHub](https://github.com/mansueli/tle/tree/master/brainfuck).

## Acknowledgments
Special thanks to the PostgreSQL and TLE communities for making database extensibility more powerful and fun!
