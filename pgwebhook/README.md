# pgwebhook

`pgwebhook` is a PostgreSQL extension designed to facilitate the creation and management of webhooks directly from your database. It works seamlessly with the Supabase platform and leverages the `pghttp` extension for making HTTP requests. This extension is ideal for developers looking to integrate real-time data changes in PostgreSQL with external services and applications through webhooks.

## Prerequisites

- PostgreSQL 14 or newer
- `pghttp` extension (version 1.5.0 or newer recommended)

## Installation

For Supabase users or those with TLE (Trusted Language Extensions) installed, you can easily install `pgwebhook` using the following SQL commands:

```sql
SELECT dbdev.install('mansueli@pgwebhook');
CREATE EXTENSION "mansueli@pgwebhook" VERSION '0.1.1';
```

### Manual Installation

If you're not using Supabase or TLE, you can manually install `pgwebhook` by running the SQL script for the latest version (e.g., `pgwebhook--0.1.1.sql`). Ensure you have the `pgsql-http` extension installed on your PostgreSQL database. For detailed instructions, visit the [pgsql-http GitHub repository](https://github.com/pramsey/pgsql-http).

## Usage

This extension supports two main usage scenarios: direct calls to external services and webhook triggers.

### Direct Usage

#### Calling the Edge Functions Within the Database (e.g., pg_cron or through an RPC)

We believe that while this extension offers a lot of options, most projects will benefit from a wrapper that sets defaults around it. For example, let's say OpenAI restricts calls to allowed regions, or you need to keep your Edge Function calls within a few subregions for GDPR compliance.

```sql
-- Create wrapper function in the public schema
CREATE OR REPLACE FUNCTION public.euro_edge (func TEXT, data JSONB) RETURNS JSONB LANGUAGE plpgsql
AS $function$
DECLARE
    custom_headers JSONB;
    allowed_regions TEXT[] := ARRAY['eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-north-1', 'eu-central-1'];
BEGIN
    -- Set headers with anon key and Content-Type
    custom_headers := jsonb_build_object('Authorization', vault.get_anon_key(bearer := true),
                                         'Content-Type', 'application/json');
    -- Call edge_wrapper function with default values
    RETURN hook.edge_wrapper(url := ('https://supanacho.supabase.co/functions/v1/' || func),
                             headers := custom_headers,
                             payload := data,
                             max_retries := 5,
                             allowed_regions := allowed_regions);
END;
$function$;
```

Then you can call this from the supabase-js client like:

```js
const { data, error } = await supabase.rpc('euro_edge', {
    func: 'hello-world',
    data: JSON.stringify({ name: 'John Doe' })
});
```

### Webhooks

#### Creating Webhook Triggers

To create a webhook trigger for a table, use the `hook.webhook_trigger` function as follows:

```sql
CREATE TRIGGER your_trigger_name
AFTER INSERT OR UPDATE OR DELETE ON your_table
FOR EACH ROW EXECUTE FUNCTION hook.webhook_trigger(
    'https://your-webhook-url.com',
    'POST',
    '{"Content-Type": "application/json"}',
    '{}',
    5000,
    'your_custom_handler'
);
```

#### Creating Edge Webhook Triggers

To create an edge webhook trigger that retries requests and handles regional headers, use the `hook.edgehook_trigger` function:

```sql
CREATE TRIGGER your_edge_trigger_name
AFTER INSERT OR UPDATE OR DELETE ON your_table
FOR EACH ROW EXECUTE FUNCTION hook.edgehook_trigger(
    'https://your-webhook-url.com',
    'POST',
    '{"Content-Type": "application/json"}',
    '{}',
    5000,
    ARRAY['region1', 'region2']
);
```

### Parameters

- **url**: The URL to send the webhook request to.
- **method**: HTTP method to use (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`).
- **headers**: JSON object containing the headers for the HTTP request.
- **params**: JSON object containing the query parameters for the HTTP request.
- **timeout_ms**: Timeout in milliseconds for the HTTP request.
- **max_retries**: Maximum number of retries for the HTTP request in case of failures.
- **allowed_regions**: Array of allowed regions for edge triggers.
- **custom_handler**: Optional custom handler function for constructing the payload.

### List of Allowed Regions

- ap-northeast-1
- ap-northeast-2
- ap-south-1
- ap-southeast-1
- ap-southeast-2
- ca-central-1
- eu-central-1
- eu-west-1
- eu-west-2
- eu-west-3
- sa-east-1
- us-east-1
- us-west-1
- us-west-2

### Using Triggers on a Table

#### Create a Trigger Using a PL/pgSQL Custom Handler

```sql
CREATE OR REPLACE FUNCTION hook.custom_handler_function(payload jsonb)
RETURNS jsonb AS $$
DECLARE
    new_payload jsonb;
BEGIN
    -- Modify the payload as needed
    -- Example: Add a new field to the payload
    new_payload := payload || jsonb_build_object('additional_info', 'This is extra info');

    -- Example: Remove a sensitive field
    new_payload := new_payload - 'sensitive_field';

    -- Return the modified payload
    RETURN new_payload;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER your_trigger_name
AFTER INSERT OR UPDATE OR DELETE ON your_table
FOR EACH ROW EXECUTE FUNCTION hook.webhook_trigger(
    'https://your-webhook-url.com',
    'POST',
    '{"Content-Type": "application/json"}',
    '{}',
    5000,
    'hook.custom_handler_function'
);
```

#### Create a Trigger Using a PLv8 Custom Handler

```sql
CREATE OR REPLACE FUNCTION hook.custom_handler_function_js(payload jsonb)
RETURNS jsonb AS $$
var newPayload = payload;

// Modify the payload: Add new field and remove a sensitive field
newPayload.additional_info = 'This is extra info';
delete newPayload.sensitive_field;

return newPayload;
$$ LANGUAGE plv8;

CREATE TRIGGER your_trigger_name
AFTER INSERT OR UPDATE OR DELETE ON your_table
FOR EACH ROW EXECUTE FUNCTION hook.webhook_trigger(
    'https://your-webhook-url.com',
    'POST',
    '{"Content-Type": "application/json"}',
    '{}',
    5000,
    'hook.custom_handler_function_js'
);
```

## License

This code is licensed under the [Apache License 2.0](https://github.com/mansueli/tle/blob/main/LICENSE).
