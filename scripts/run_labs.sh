#!/usr/bin/env bash
# Utiliser l'instance de TP dédiée. Les bases BlogApp/Pagila/StackExchange sont recréées.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/prepare_data.py
mkdir -p rapports/logs
export PGUSER="${PGUSER:-labuser}"
psql -X -v ON_ERROR_STOP=1 -d blogapp_lab -c 'SELECT version();'
for file in sql/01_lab01_environment.sql sql/00_pagila.sql sql/02_lab02_ddl_dml.sql \
            sql/03_lab03_queries.sql sql/04_lab04_queries.sql projet_final.sql \
            tests/projet.sql tests/optimisation.sql tests/benchmark.sql sql/demo.sql; do
    log="rapports/logs/$(basename "$file" .sql).log"
    psql -X -v ON_ERROR_STOP=1 -v repo_root="$PWD" -d blogapp_lab -f "$file" > "$log" 2>&1 || {
        tail -30 "$log"; exit 1;
    }
    echo "$file : OK"
done
