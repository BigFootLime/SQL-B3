\set ON_ERROR_STOP on
\connect blogapp_lab
DROP DATABASE IF EXISTS pagila WITH (FORCE);
CREATE DATABASE pagila OWNER labuser;
\connect pagila
\ir ../sources/pagila/pagila-schema.sql
\ir ../sources/pagila/pagila-data.sql
ANALYZE;

