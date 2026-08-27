\set ON_ERROR_STOP on
\connect blogapp_lab
-- Le dump Pagila utilise postgres comme propriétaire, même si l'instance
-- a été initialisée avec un autre superutilisateur.
DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres') THEN
        CREATE ROLE postgres NOLOGIN;
    END IF;
END $$;
DROP DATABASE IF EXISTS pagila WITH (FORCE);
CREATE DATABASE pagila OWNER labuser;
\connect pagila
\ir ../sources/pagila/pagila-schema.sql
\ir ../sources/pagila/pagila-data.sql
ANALYZE;
