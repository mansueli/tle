DROP TABLE IF EXISTS hook.responses;
DROP SEQUENCE IF EXISTS hook.responses_id_seq;

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
    ALTER COLUMN id SET DEFAULT nextval('hook.responses_id_seq')