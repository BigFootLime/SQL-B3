\set ON_ERROR_STOP on
\pset pager off
\connect stackexchange
-- La requête littérale du cours, ancrée sur NOW(), ne rencontre plus de posts
-- récents dans le dump. Pour comparer des résultats non vides, les deux
-- variantes utilisent la même dernière année du jeu de données.
CREATE TEMP VIEW avant AS
SELECT p.id,p.title,u.display_name AS auteur,
       (SELECT COUNT(*) FROM comments c WHERE c.post_id=p.id) AS commentaires,
       (SELECT COUNT(*) FROM votes v WHERE v.post_id=p.id AND v.vote_type_id=2) AS upvotes
FROM posts p LEFT JOIN users u ON u.id=p.owner_user_id
WHERE p.post_type_id=1
  AND p.creation_date >= (SELECT MAX(creation_date) FROM posts)-INTERVAL '1 year'
ORDER BY upvotes DESC,p.id LIMIT 100;

CREATE TEMP VIEW apres AS
WITH candidats AS MATERIALIZED (
    SELECT id,title,owner_user_id FROM posts WHERE post_type_id=1
      AND creation_date >= (SELECT MAX(creation_date) FROM posts)-INTERVAL '1 year'
), votes_par_post AS (
    SELECT v.post_id,COUNT(*) AS upvotes FROM votes v
    JOIN candidats c ON c.id=v.post_id WHERE v.vote_type_id=2 GROUP BY v.post_id
), premiers AS MATERIALIZED (
    SELECT c.*,COALESCE(v.upvotes,0) AS upvotes FROM candidats c
    LEFT JOIN votes_par_post v ON v.post_id=c.id
    ORDER BY upvotes DESC,c.id LIMIT 100
), commentaires_par_post AS (
    SELECT c.post_id,COUNT(*) AS commentaires FROM comments c
    JOIN premiers p ON p.id=c.post_id GROUP BY c.post_id
)
SELECT p.id,p.title,u.display_name AS auteur,COALESCE(c.commentaires,0) AS commentaires,p.upvotes
FROM premiers p LEFT JOIN users u ON u.id=p.owner_user_id
LEFT JOIN commentaires_par_post c ON c.post_id=p.id
ORDER BY p.upvotes DESC,p.id;

DO $$ BEGIN
    IF EXISTS ((TABLE avant EXCEPT ALL TABLE apres) UNION ALL (TABLE apres EXCEPT ALL TABLE avant)) THEN
        RAISE EXCEPTION 'Les deux versions ne retournent pas les memes resultats';
    END IF;
END $$;
CREATE TEMP TABLE mesures(version TEXT, ms DOUBLE PRECISION);
CREATE TEMP TABLE plans(version TEXT, plan JSONB);
DO $$
DECLARE n INTEGER; started timestamptz; p JSONB;
BEGIN
    FOR n IN 1..30 LOOP
        started:=clock_timestamp(); PERFORM * FROM avant;
        INSERT INTO mesures VALUES('avant',extract(epoch FROM clock_timestamp()-started)*1000);
        started:=clock_timestamp(); PERFORM * FROM apres;
        INSERT INTO mesures VALUES('apres',extract(epoch FROM clock_timestamp()-started)*1000);
    END LOOP;
    EXECUTE 'EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) SELECT * FROM avant' INTO p;
    INSERT INTO plans VALUES('avant',p);
    EXECUTE 'EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) SELECT * FROM apres' INTO p;
    INSERT INTO plans VALUES('apres',p);
END $$;
\pset format unaligned
\pset tuples_only on
\o rapports/optimisation.json
SELECT jsonb_pretty(jsonb_build_object(
    'date_mesure',clock_timestamp(),'resultats_identiques',true,
    'lignes_comparees',(SELECT COUNT(*) FROM avant),
    'lignes_avec_now',(SELECT COUNT(*) FROM posts WHERE post_type_id=1 AND creation_date >= NOW()-INTERVAL '1 year'),
    'date_reference',(SELECT MAX(creation_date) FROM posts),
    'mesures',(SELECT jsonb_agg(to_jsonb(t)) FROM (
        SELECT version,COUNT(*) AS repetitions,ROUND(AVG(ms)::numeric,3) AS moyenne_ms,
               ROUND(percentile_cont(0.5) WITHIN GROUP(ORDER BY ms)::numeric,3) AS mediane_ms
        FROM mesures GROUP BY version ORDER BY version) t),
    'gain_moyenne_pct',(SELECT ROUND((100*(1-
        AVG(ms) FILTER(WHERE version='apres')/NULLIF(AVG(ms) FILTER(WHERE version='avant'),0)))::numeric,2) FROM mesures),
    'plans',(SELECT jsonb_object_agg(version,plan) FROM plans)));
\o
\echo 'Comparaison exportee avec les plans complets et leurs buffers.'
