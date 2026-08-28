\set ON_ERROR_STOP on
\pset pager off
\connect stackexchange
CREATE TEMP TABLE bench(scenario TEXT, ms DOUBLE PRECISION, resultats INTEGER);
DO $$
DECLARE i INTEGER; q TEXT; start_time timestamptz; n INTEGER;
        queries TEXT[] := ARRAY['coffee','espresso grinder','brewing temperature','espressso','cold brew'];
BEGIN
    -- Cinq requêtes distinctes, répétées 30 fois. Cache applicatif vide puis
    -- rempli. Le cache de pages PostgreSQL reste chaud dans les deux cas.
    FOR i IN 1..150 LOOP
        q := queries[1 + (i-1)%5];
        DELETE FROM search_cache WHERE scope=search_scope();
        start_time := clock_timestamp();
        SELECT COUNT(*) INTO n FROM advanced_search(q);
        INSERT INTO bench VALUES ('sans_cache_applicatif',extract(epoch FROM clock_timestamp()-start_time)*1000,n);
        start_time := clock_timestamp();
        SELECT COUNT(*) INTO n FROM advanced_search(q);
        INSERT INTO bench VALUES ('avec_cache_applicatif',extract(epoch FROM clock_timestamp()-start_time)*1000,n);
    END LOOP;
END $$;
\pset format unaligned
\pset tuples_only on
\o rapports/benchmark.json
SELECT jsonb_pretty(jsonb_build_object(
    'date_mesure',clock_timestamp(),'postgresql',version(),
    'donnees',jsonb_build_object('posts',(SELECT COUNT(*) FROM posts),'votes',(SELECT COUNT(*) FROM votes)),
    'mesures',(SELECT jsonb_agg(to_jsonb(x)) FROM (
        SELECT scenario,COUNT(*) AS appels,ROUND(AVG(ms)::numeric,3) AS moyenne_ms,
               ROUND(percentile_cont(0.50) WITHIN GROUP(ORDER BY ms)::numeric,3) AS mediane_ms,
               ROUND(percentile_cont(0.95) WITHIN GROUP(ORDER BY ms)::numeric,3) AS p95_ms,
               ROUND(MAX(ms)::numeric,3) AS maximum_ms,
               ROUND((1000*COUNT(*)/SUM(ms))::numeric,2) AS requetes_par_seconde_sequentiel,
               COUNT(*) FILTER(WHERE resultats>0) AS appels_avec_resultats
        FROM bench GROUP BY scenario ORDER BY scenario) x),
    'taille_base',pg_size_pretty(pg_database_size(current_database())),
    'tables_et_index',(SELECT jsonb_agg(to_jsonb(t)) FROM (
        SELECT relname,pg_size_pretty(pg_table_size(relid)) AS table_et_toast,
               pg_size_pretty(pg_indexes_size(relid)) AS index
        FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 20) t),
    'pg_stat_statements',(SELECT jsonb_agg(to_jsonb(s)) FROM (
        SELECT query,calls,ROUND(mean_exec_time::numeric,3) AS moyenne_ms,rows
        FROM pg_stat_statements WHERE query LIKE '%advanced_search%'
          AND dbid=(SELECT oid FROM pg_database WHERE datname=current_database())
        ORDER BY calls DESC LIMIT 5) s)));
\o
\pset tuples_only off
\pset format aligned
REFRESH MATERIALIZED VIEW search_analytics;
TABLE search_analytics;
