---------------------- CREATE SCHEMA ---------------------------------

CREATE SCHEMA chat_schema;

ALTER DATABASE chatdb SET chat_schema.schema_version = 0;

--------------------------- USER -------------------------------------

/*
 * Table chat_schema.user holds all the user information  
 */

CREATE TABLE chat_schema.user(
    id BIGSERIAL PRIMARY KEY,
    created_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    name TEXT NOT NULL UNIQUE,
    socket TEXT NOT NULL,
    active BOOLEAN DEFAULT true
);

------------------------- MESSAGE ------------------------------------

/*
 * Table chat_schema.message holds all the message information  
 */

CREATE TABLE chat_schema.message(
    id BIGSERIAL PRIMARY KEY,
    created_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sender TEXT NOT NULL REFERENCES chat_schema.user(name),
    receiver TEXT NOT NULL REFERENCES chat_schema.user(name),
    content TEXT NOT NULL
);
