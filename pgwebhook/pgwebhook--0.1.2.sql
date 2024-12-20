
-- <> Create http extension
CREATE EXTENSION IF NOT EXISTS http SCHEMA extensions;

-- Create hook schema
CREATE SCHEMA hook;

GRANT USAGE ON SCHEMA hook TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA hook GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA hook GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA hook GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;

-- hook.migrations definition
CREATE TABLE hook.migrations (
    version text PRIMARY KEY,
    inserted_at timestamptz NOT NULL DEFAULT NOW()
);

-- Initial hook migration
INSERT INTO hook.migrations (version) VALUES ('initial');

-- hook.hooks definition
CREATE UNLOGGED TABLE hook.responses (
    id BIGINT NOT NULL PRIMARY KEY,
    hook_table_id INTEGER NOT NULL,
    hook_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    response_body JSONB,
    request_id BIGINT
);

CREATE UNLOGGED SEQUENCE hook.responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE hook.responses
    ALTER COLUMN id SET DEFAULT nextval('hook.responses_id_seq');

CREATE INDEX hook_responses_request_id_idx ON hook.responses USING btree (request_id);
CREATE INDEX hook_responses_h_table_id_h_name_idx ON hook.responses USING btree (hook_table_id, hook_name);

CREATE OR REPLACE FUNCTION hook.edge_wrapper(
    url TEXT,
    method TEXT DEFAULT 'POST',
    headers JSONB DEFAULT '{"Content-Type": "application/json"}'::jsonb,
    params JSONB DEFAULT '{}'::jsonb,
    payload JSONB DEFAULT '{}'::jsonb, -- Payload as JSONB
    timeout_ms INTEGER DEFAULT 5000,
    max_retries INTEGER DEFAULT 0,
    allowed_regions TEXT[] DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
    retry_count INTEGER := 0;
    retry_delays DOUBLE PRECISION[] := ARRAY[0, 0.250, 0.500, 1.000, 2.500, 5.000];
    succeeded BOOLEAN := FALSE;
    current_region_index INTEGER := 1; -- Start index at 1 for PostgreSQL array
    combined_headers JSONB;
    response_json JSONB;
BEGIN
    -- Check if headers is a valid JSON object
    IF headers IS NULL OR NOT jsonb_typeof(headers) = 'object' THEN
        RAISE EXCEPTION 'Invalid headers parameter: %', headers;
    END IF;

    -- Check if params is a valid JSON object
    IF params IS NULL OR NOT jsonb_typeof(params) = 'object' THEN
        RAISE EXCEPTION 'Invalid params parameter: %', params;
    END IF;

    -- Check if payload is a valid JSON object
    IF payload IS NULL OR NOT jsonb_typeof(payload) = 'object' THEN
        RAISE EXCEPTION 'Invalid payload parameter: %', payload;
    END IF;

    -- Check if allowed_regions is provided and not empty
    IF allowed_regions IS NOT NULL AND cardinality(allowed_regions) = 0 THEN
        RAISE EXCEPTION 'allowed_regions parameter cannot be an empty array';
    END IF;

    -- Check if retry_delays has enough elements
    IF cardinality(retry_delays) < max_retries + 1 THEN
        RAISE EXCEPTION 'retry_delays array must have at least % elements', max_retries + 1;
    END IF;

    -- Retry loop
    WHILE NOT succeeded AND retry_count <= max_retries LOOP
        -- Start with original headers and add x-region if necessary
        combined_headers := headers;

        -- Set x-region header if allowed_regions is provided and not empty
        IF allowed_regions IS NOT NULL AND cardinality(allowed_regions) > 0 THEN
            combined_headers := combined_headers || jsonb_build_object('x-region', allowed_regions[current_region_index]);
        END IF;

        -- Perform sleep if not the first attempt
        IF retry_count > 0 THEN
            PERFORM pg_sleep(retry_delays[retry_count]);
        END IF;

        retry_count := retry_count + 1;

        -- Increment region index, wrapping around if necessary
        IF allowed_regions IS NOT NULL AND cardinality(allowed_regions) > 0 THEN
            current_region_index := current_region_index + 1;
            IF current_region_index > cardinality(allowed_regions) THEN
                current_region_index := 1;
            END IF;
        END IF;

        BEGIN
            RAISE WARNING 'headers:%s', combined_headers;
            -- Call the simplified HTTP request function
            response_json := hook.http_request(url, method, combined_headers, params, payload, timeout_ms);

            -- Check the status code
            IF (response_json->>'status_code')::INTEGER < 500 THEN
                succeeded := TRUE;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                IF retry_count > max_retries THEN
                    -- If retries exhausted, re-raise exception
                    RAISE EXCEPTION 'HTTP request failed after % retries. SQL Error: { %, % }',
                        max_retries, SQLERRM, SQLSTATE;
                END IF;
        END;
    END LOOP;

    RETURN response_json;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hook.http_request(
    url TEXT,
    method TEXT DEFAULT 'POST',
    headers JSONB DEFAULT '{"Content-Type": "application/json"}'::jsonb,
    params JSONB DEFAULT '{}'::jsonb,
    payload JSONB DEFAULT '{}'::jsonb,
    timeout_ms INTEGER DEFAULT 5000
) RETURNS jsonb AS $$
DECLARE
    http_response extensions.http_response;
    status_code integer := 0;
    response_json jsonb;
    response_text text;
    header_array extensions.http_header[];
    request extensions.http_request;
BEGIN
    -- Set the timeout option
    IF timeout_ms > 0 THEN
        PERFORM http_set_curlopt('CURLOPT_TIMEOUT_MS', timeout_ms::text);
    END IF;

    -- Convert headers JSONB to http_header array
    SELECT array_agg(extensions.http_header(key, value::text))
    FROM jsonb_each_text(headers)
    INTO header_array;

    -- Construct the http_request composite type
    request := ROW(method, url, header_array, 'application/json', payload::text)::extensions.http_request;

    -- Make the HTTP request
    http_response := http(request);
    status_code := http_response.status;

    -- Attempt to extract JSONB response content
    BEGIN
        response_json := http_response.content::jsonb;
    EXCEPTION
        WHEN others THEN
            -- If extraction fails, store response body as string
            response_text := http_response.content;
            response_json := jsonb_build_object('status_code', status_code, 'response', response_text);
    END;

    RETURN jsonb_build_object('status_code', status_code, 'response', response_json);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION hook.webhook_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    request_id bigint;
    payload jsonb;
    url text := TG_ARGV[0]::text;
    method text := TG_ARGV[1]::text;
    headers jsonb;
    params jsonb;
    timeout_ms integer;
    max_retries integer := 5;
    retry_count integer := 0;
    retry_delays double precision[] := ARRAY[0, 0.250, 0.500, 1.000, 2.500, 5.000];
    custom_handler text := TG_ARGV[5]::text;
    response_json jsonb;
    succeeded boolean := FALSE;
BEGIN
    -- Validate input arguments
    IF url IS NULL OR url = 'null' THEN
        RAISE EXCEPTION 'url argument is missing';
    END IF;

    IF method IS NULL OR method = 'null' THEN
        RAISE EXCEPTION 'method argument is missing';
    END IF;

    IF TG_ARGV[2] IS NULL OR TG_ARGV[2] = 'null' THEN
        headers := '{"Content-Type": "application/json"}'::jsonb;
    ELSE
        headers := TG_ARGV[2]::jsonb;
    END IF;

    IF TG_ARGV[3] IS NULL OR TG_ARGV[3] = 'null' THEN
        params := '{}'::jsonb;
    ELSE
        params := TG_ARGV[3]::jsonb;
    END IF;

    IF TG_ARGV[4] IS NULL OR TG_ARGV[4] = 'null' THEN
        timeout_ms := 5000;
    ELSE
        timeout_ms := TG_ARGV[4]::integer;
    END IF;

    -- Validate method
    IF NOT method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD') THEN
        RAISE EXCEPTION 'Invalid HTTP method: %', method;
    END IF;

    -- Validate headers
    IF headers IS NULL OR NOT jsonb_typeof(headers) = 'object' THEN
        RAISE EXCEPTION 'Invalid headers parameter: %', headers;
    END IF;

    -- Validate params
    IF params IS NULL OR NOT jsonb_typeof(params) = 'object' THEN
        RAISE EXCEPTION 'Invalid params parameter: %', params;
    END IF;

    -- Attempt to call custom payload handler
    BEGIN
        EXECUTE format('SELECT %s($1)', custom_handler) INTO payload USING jsonb_build_object(
            'old_record', TO_JSONB(OLD),
            'record', TO_JSONB(NEW),
            'type', TG_OP,
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA
        );
    EXCEPTION
        WHEN others THEN
            -- Fallback to default payload structure if custom handler fails
            payload := jsonb_build_object(
                'old_record', TO_JSONB(OLD),
                'record', TO_JSONB(NEW),
                'type', TG_OP,
                'table', TG_TABLE_NAME,
                'schema', TG_TABLE_SCHEMA
            );
    END;

    -- Retry loop for HTTP request
    WHILE NOT succeeded AND retry_count <= max_retries LOOP
        -- Sleep based on retry_count, using 1-based indexing for retry_delays array
        IF retry_count > 0 THEN
            PERFORM pg_sleep(retry_delays[retry_count]);
        END IF;

        retry_count := retry_count + 1;

        BEGIN
            -- Call the HTTP request function
            response_json := hook.http_request(url, method, headers, params, payload, timeout_ms);

            -- Check the status code
            IF (response_json->>'status_code')::INTEGER < 500 THEN
                succeeded := TRUE;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                IF retry_count > max_retries THEN
                    -- If retries exhausted, re-raise exception
                    RAISE EXCEPTION 'HTTP request failed after % retries. SQL Error: { %, % }',
                        max_retries, SQLERRM, SQLSTATE;
                END IF;
        END;
    END LOOP;

    -- Validate response JSON structure
    IF response_json IS NULL OR NOT jsonb_typeof(response_json) = 'object' THEN
        RAISE EXCEPTION 'Inval...
