\set ON_ERROR_STOP on
\pset pager off
\connect stackexchange
BEGIN;
CREATE FUNCTION assert_true(ok BOOLEAN, message TEXT) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF ok IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'ECHEC : %', message; END IF;
    RAISE NOTICE 'OK : %', message;
END $$;

SELECT assert_true((SELECT COUNT(*) FROM posts)=4525,'import des 4525 posts Coffee');
SELECT assert_true((SELECT COUNT(*) FROM votes)=(SELECT COUNT(*) FROM votes_old),'migration de tous les votes');
SELECT assert_true((SELECT COUNT(*) FROM pg_inherits WHERE inhparent='votes'::regclass)=13,
                   '12 partitions mensuelles et une partition par defaut');
SELECT assert_true(NOT EXISTS(SELECT FROM posts WHERE search_vector IS NULL),'vecteurs FTS remplis');
SELECT assert_true(EXISTS(SELECT FROM smart_search('espressso') WHERE match_type='fuzzy'),
                   'tolere une faute de frappe');
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('coffee','{}',1,5))=5,'pagination limitee');
SELECT assert_true(NOT EXISTS(
    SELECT post_id FROM advanced_search('coffee','{}',1,5)
    INTERSECT SELECT post_id FROM advanced_search('coffee','{}',2,5)), 'pages sans doublons');
SELECT COUNT(*) FROM advanced_search('coffee','{}',1,5);
SELECT assert_true((SELECT cache_hit FROM search_log ORDER BY id DESC LIMIT 1),'cache utilise au second appel');
SELECT assert_true(NOT EXISTS(SELECT FROM faceted_search(
    '{"date_range":{"from":"2099-01-01","to":"2099-12-31"}}')),'date_range respecte');
SELECT assert_true(NOT EXISTS(SELECT FROM faceted_search('{"min_score":2147483647}')),'score minimum respecte');
SELECT assert_true(NOT EXISTS(SELECT FROM faceted_search('{"tags":["tag-absent-xyz"]}')),'tag absent exclut les resultats');
SELECT assert_true(EXISTS(SELECT FROM get_search_suggestions('cof')),'autocompletion');
SELECT assert_true(get_dashboard_metrics() ? 'p95_ms','tableau de bord temps reel');
DO $$ BEGIN
    BEGIN PERFORM advanced_search(''); RAISE EXCEPTION 'Recherche vide acceptee';
    EXCEPTION WHEN invalid_parameter_value THEN RAISE NOTICE 'OK : recherche vide refusee'; END;
    BEGIN PERFORM advanced_search('coffee','{}',0); RAISE EXCEPTION 'Page zero acceptee';
    EXCEPTION WHEN invalid_parameter_value THEN RAISE NOTICE 'OK : page invalide refusee'; END;
    BEGIN PERFORM advanced_search('coffee','{"tags":"coffee"}'); RAISE EXCEPTION 'Filtre mal type accepte';
    EXCEPTION WHEN invalid_parameter_value THEN RAISE NOTICE 'OK : type JSON invalide refuse'; END;
    BEGIN PERFORM advanced_search('coffee','{"filtre_inconnu":true}'); RAISE EXCEPTION 'Filtre inconnu accepte';
    EXCEPTION WHEN invalid_parameter_value THEN RAISE NOTICE 'OK : filtre inconnu refuse'; END;
END $$;

-- Les identifiants négatifs sont propres à ces tests. Tout est annulé à la fin.
INSERT INTO users(id,creation_date,display_name) VALUES
(-99001,NOW(),'Auteur test'),(-99002,NOW(),'Lecteur test');
INSERT INTO post_ids(id,creation_date)
SELECT n, TIMESTAMP '2026-08-27 12:00' FROM generate_series(-99006,-99001) n;
INSERT INTO posts(id,post_type_id,creation_date,title,body,owner_user_id,tenant_id,visibility,metadata)
VALUES
(-99001,1,'2026-08-27 12:00','qxjvbpznmtr public','Public coffee brewing',-99001,1,'public','{}'),
(-99002,1,'2026-08-27 12:00','qxjvbpznmtr prive','Private coffee brewing',-99001,1,'private','{}'),
(-99003,1,'2026-08-27 12:00','qxjvbpznmtr moderation','Moderation coffee brewing',-99001,1,'moderation','{}'),
(-99004,1,'2026-08-27 12:00','qxjvbpznmtr autre tenant','Other tenant coffee brewing',-99001,2,'public','{}'),
(-99005,1,'2026-08-27 12:00','Les chevaux dans les prairies','Les chevaux courent dans les prairies.',-99001,1,'public','{"language":"fr"}'),
(-99006,2,'2026-08-27 12:00',NULL,'Reponse de test',-99002,1,'public','{}');
UPDATE posts SET parent_id=-99001,score=10 WHERE id=-99006;
SELECT assert_true((SELECT answer_count FROM posts WHERE id=-99001)=1,'compteur mis a jour apres rattachement');
UPDATE posts SET accepted_answer_id=-99006,view_count=1000 WHERE id=-99001;
SELECT assert_true(EXISTS(SELECT FROM badges WHERE user_id=-99002 AND name='Scholar'),
                   'Scholar attribue a auteur de reponse acceptee');
SELECT assert_true(EXISTS(SELECT FROM badges WHERE user_id=-99002 AND name='Nice Answer'),'Nice Answer');
SELECT assert_true(EXISTS(SELECT FROM badges WHERE user_id=-99001 AND name='Popular Question'),'Popular Question');
INSERT INTO votes(id,post_id,vote_type_id,creation_date,user_id)
VALUES(-99001,-99001,2,NOW(),-99002);
SELECT assert_true(EXISTS(SELECT FROM badges WHERE user_id=-99002 AND name='Supporter'),'Supporter sur insertion vote');
UPDATE votes SET vote_type_id=3 WHERE id=-99001;
SELECT assert_true(EXISTS(SELECT FROM badges WHERE user_id=-99002 AND name='Critic'),'Critic sur modification vote');
SELECT check_and_award_badges(-99002);
SELECT check_and_award_badges(-99002);
SELECT assert_true(NOT EXISTS(SELECT name FROM badges WHERE user_id=-99002 GROUP BY name HAVING COUNT(*)>1),
                   'attributions de badges idempotentes');
SELECT assert_true(EXISTS(SELECT FROM advanced_search('cheval','{"language":"fr"}') WHERE post_id=-99005),
                   'recherche francaise avec racinisation');
SELECT assert_true(EXISTS(SELECT FROM advanced_search('qxjvbpznmtr','{"language":"xx"}') WHERE post_id=-99001),
                   'langue inconnue : repli anglais');
SELECT assert_true(EXISTS(SELECT FROM faceted_search('{"metadata":{"language":"fr"}}') WHERE post_id=-99005),
                   'filtre de metadonnees JSONB');

SELECT set_config('app.current_tenant_id','1',true);
SELECT set_config('app.current_user_id','-99002',true);
SET LOCAL ROLE tenant_reader;
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr'))=1,'lecteur voit seulement le post public de son tenant');
SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr');
SELECT set_config('app.current_tenant_id','2',true);
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr'))=1,'changement de tenant ne reutilise pas le mauvais cache');
SELECT assert_true((SELECT post_id FROM advanced_search('qxjvbpznmtr'))=-99004,'resultat du tenant 2');
SELECT set_config('app.current_tenant_id','1',true);
SELECT set_config('app.current_user_id','-99001',true);
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr'))=2,'proprietaire voit aussi son post prive');
DO $$ BEGIN
    BEGIN PERFORM COUNT(*) FROM posts_default; RAISE EXCEPTION 'Acces direct partition autorise';
    EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK : acces direct aux partitions refuse'; END;
    BEGIN PERFORM COUNT(*) FROM user_secrets; RAISE EXCEPTION 'Acces secrets autorise';
    EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK : acces aux secrets refuse'; END;
END $$;
SET LOCAL ROLE tenant_moderator;
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr'))=3,'moderateur voit les trois visibilites du tenant');
SET LOCAL ROLE lab_admin;
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr'))=4,'administrateur voit les deux tenants');
RESET ROLE;
UPDATE posts SET visibility='private' WHERE id=-99001;
SELECT set_config('app.current_user_id','-99002',true);
SET LOCAL ROLE tenant_reader;
SELECT assert_true((SELECT COUNT(*) FROM advanced_search('qxjvbpznmtr'))=0,'changement de visibilite invalide le cache');
RESET ROLE;
DELETE FROM posts WHERE id=-99006;
SELECT assert_true((SELECT answer_count FROM posts WHERE id=-99001)=0,'suppression reponse decremente le compteur');
SELECT assert_true(EXISTS(SELECT FROM dashboard_posts WHERE descriptions_tags IS NOT NULL),'jointure avec le CSV via file_fdw');
ROLLBACK;
\echo 'Tous les tests fonctionnels sont passes. Donnees de test annulees.'
