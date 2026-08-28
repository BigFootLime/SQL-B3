\set ON_ERROR_STOP on
\pset pager off
\timing on
\connect stackexchange
BEGIN;
\echo '1. Recherche et second appel avec cache'
SELECT post_id,title,relevance FROM advanced_search('coffee brewing','{}',1,5);
SELECT post_id,title,relevance FROM advanced_search('coffee brewing','{}',1,5);
SELECT query_text,cache_hit,round(duration_ms::numeric,3) AS ms
FROM search_log WHERE scope=search_scope() ORDER BY id DESC LIMIT 2;

\echo '2. Faute de frappe et filtres'
SELECT * FROM smart_search('espressso');
SELECT post_id,title FROM advanced_search('espresso',
    '{"tags":["espresso"],"min_score":1,"date_from":"2015-01-01"}',1,5);
SELECT * FROM get_search_suggestions('cof',5);

\echo '3. Isolation par tenant avec un vrai role lecteur'
SELECT set_config('app.current_tenant_id','1',true);
SELECT set_config('app.current_user_id','0',true);
SET LOCAL ROLE tenant_reader;
SELECT current_user,tenant_id,COUNT(*) FROM posts GROUP BY tenant_id;
SELECT post_id,title FROM advanced_search('coffee','{}',1,3);
SELECT set_config('app.current_tenant_id','2',true);
SELECT current_user,tenant_id,COUNT(*) FROM posts GROUP BY tenant_id;
SELECT post_id,title FROM advanced_search('coffee','{}',1,3);
RESET ROLE;

\echo '4. Analytique et federation'
SELECT get_dashboard_metrics();
-- Fenêtre longue explicitement choisie pour les données historiques.
SELECT * FROM get_trending_tags(INTERVAL '20 years') LIMIT 5;
SELECT * FROM get_rising_questions(INTERVAL '20 years') LIMIT 5;
SELECT * FROM dashboard_posts LIMIT 3;
ROLLBACK;
\echo 'Demonstration terminee, recherches temporaires annulees.'
