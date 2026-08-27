\set ON_ERROR_STOP on
\pset pager off
\timing on

\connect pagila
\echo '=== LAB 04 - CTE, fenetres et sous-requetes ==='

\echo '=== Exercice 4.1 - CTE de base ==='
-- Tache 1
WITH moyenne AS (
    SELECT AVG(rental_rate) AS tarif_moyen
    FROM film
)
SELECT f.film_id, f.title, f.rental_rate, m.tarif_moyen
FROM film f
CROSS JOIN moyenne m
WHERE f.rental_rate > m.tarif_moyen
ORDER BY f.rental_rate DESC, f.title;

-- Tache 2 : chaque table un-a-plusieurs est agregee avant la jointure.
WITH rental_stats AS (
    SELECT customer_id, COUNT(*) AS nombre_locations
    FROM rental
    GROUP BY customer_id
), payment_stats AS (
    SELECT customer_id, SUM(amount) AS total_depense
    FROM payment
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    concat(c.first_name, ' ', c.last_name) AS client,
    COALESCE(rs.nombre_locations, 0) AS nombre_locations,
    COALESCE(ps.total_depense, 0) AS total_depense
FROM customer c
LEFT JOIN rental_stats rs ON rs.customer_id = c.customer_id
LEFT JOIN payment_stats ps ON ps.customer_id = c.customer_id
ORDER BY total_depense DESC, c.customer_id;

\connect blogapp
\echo '=== Exercice 4.2 - CTE recursives ==='
-- Tache 1 : + 1 conserve le type DATE et evite le piege DATE + INTERVAL.
WITH RECURSIVE calendrier AS (
    SELECT CURRENT_DATE AS jour
    UNION ALL
    SELECT jour + 1
    FROM calendrier
    WHERE jour < CURRENT_DATE + 29
)
SELECT
    jour,
    trim(to_char(jour, 'TMDay')) AS nom_jour,
    extract(isodow FROM jour) IN (6, 7) AS est_weekend
FROM calendrier
ORDER BY jour;

-- Tache 2 : un tableau path evite une boucle si les donnees sont corrompues.
WITH RECURSIVE fil_commentaires AS (
    SELECT
        c.comment_id,
        c.post_id,
        c.parent_id,
        c.contenu,
        c.cree_le,
        0 AS profondeur,
        ARRAY[c.comment_id] AS path
    FROM commentaires c
    WHERE c.parent_id IS NULL

    UNION ALL

    SELECT
        enfant.comment_id,
        enfant.post_id,
        enfant.parent_id,
        enfant.contenu,
        enfant.cree_le,
        parent.profondeur + 1,
        parent.path || enfant.comment_id
    FROM commentaires enfant
    JOIN fil_commentaires parent
      ON enfant.parent_id = parent.comment_id
    WHERE NOT enfant.comment_id = ANY(parent.path)
)
SELECT
    post_id,
    comment_id,
    repeat('  ', profondeur) || contenu AS commentaire_indente,
    profondeur,
    path
FROM fil_commentaires
ORDER BY post_id, path;

\connect pagila
\echo '=== Exercice 4.3 - classement ==='
-- Tache 1 : RANK conserve les ex aequo, donc une categorie peut afficher plus de 3 lignes.
WITH locations_par_film AS (
    SELECT
        c.category_id,
        c.name AS categorie,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS nombre_locations
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    JOIN film f ON f.film_id = fc.film_id
    LEFT JOIN inventory i ON i.film_id = f.film_id
    LEFT JOIN rental r ON r.inventory_id = i.inventory_id
    GROUP BY c.category_id, c.name, f.film_id, f.title
), classement AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY category_id
            ORDER BY nombre_locations DESC
        ) AS rang
    FROM locations_par_film
)
SELECT categorie, title, nombre_locations, rang
FROM classement
WHERE rang <= 3
ORDER BY categorie, rang, title;

-- Tache 2
WITH depenses AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        COALESCE(SUM(p.amount), 0) AS total_depense
    FROM customer c
    LEFT JOIN payment p ON p.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
), niveaux AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY total_depense DESC, customer_id) AS niveau
    FROM depenses
)
SELECT
    customer_id,
    concat(first_name, ' ', last_name) AS client,
    total_depense,
    niveau
FROM niveaux
ORDER BY niveau, total_depense DESC, customer_id;

\echo '=== Exercice 4.4 - acces aux valeurs ==='
-- Tache 1 : EXTRACT(EPOCH) donne la duree totale, pas seulement le composant jours.
WITH ecarts AS (
    SELECT
        customer_id,
        rental_id,
        rental_date,
        LAG(rental_date) OVER (
            PARTITION BY customer_id
            ORDER BY rental_date, rental_id
        ) AS location_precedente
    FROM rental
)
SELECT
    customer_id,
    rental_id,
    location_precedente,
    rental_date,
    round(extract(epoch FROM (rental_date - location_precedente)) / 86400.0, 2)
        AS ecart_jours
FROM ecarts
WHERE rental_date - location_precedente > INTERVAL '30 days'
ORDER BY ecart_jours DESC, customer_id;

-- Tache 2 : le cadre complet est obligatoire pour LAST_VALUE.
SELECT
    customer_id,
    payment_id,
    payment_date,
    amount,
    FIRST_VALUE(amount) OVER (
        PARTITION BY customer_id
        ORDER BY payment_date, payment_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS premier_montant,
    LAST_VALUE(amount) OVER (
        PARTITION BY customer_id
        ORDER BY payment_date, payment_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS dernier_montant
FROM payment
ORDER BY customer_id, payment_date, payment_id;

\echo '=== Exercice 4.5 - agregats fenetre ==='
-- Tache 1
WITH revenus_journaliers AS (
    SELECT payment_date::date AS jour, SUM(amount) AS revenu_journalier
    FROM payment
    GROUP BY payment_date::date
)
SELECT
    jour,
    revenu_journalier,
    SUM(revenu_journalier) OVER (
        ORDER BY jour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS revenu_cumule
FROM revenus_journaliers
ORDER BY jour;

-- Tache 2 : le calendrier ajoute les jours sans location avec la valeur 0.
WITH bornes AS (
    SELECT MIN(rental_date)::date AS debut, MAX(rental_date)::date AS fin
    FROM rental
), calendrier AS (
    SELECT generate_series(debut, fin, INTERVAL '1 day')::date AS jour
    FROM bornes
), locations_journalieres AS (
    SELECT rental_date::date AS jour, COUNT(*) AS nombre_locations
    FROM rental
    GROUP BY rental_date::date
), serie AS (
    SELECT c.jour, COALESCE(lj.nombre_locations, 0) AS nombre_locations
    FROM calendrier c
    LEFT JOIN locations_journalieres lj USING (jour)
)
SELECT
    jour,
    nombre_locations,
    ROUND(AVG(nombre_locations) OVER (
        ORDER BY jour
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moyenne_mobile_7_jours
FROM serie
ORDER BY jour;

\echo '=== Exercice 4.6 - sous-requetes ==='
-- Tache 1 : customer_id est explicitement filtre contre NULL pour securiser NOT IN.
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT r.customer_id
    FROM rental r
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film f ON f.film_id = i.film_id
    WHERE f.rating = 'NC-17'
      AND r.customer_id IS NOT NULL
)
ORDER BY c.customer_id;

-- Tache 2 : la moyenne inclut aussi les films jamais loues.
WITH compteurs AS (
    SELECT f.film_id, f.title, COUNT(r.rental_id) AS nombre_locations
    FROM film f
    LEFT JOIN inventory i ON i.film_id = f.film_id
    LEFT JOIN rental r ON r.inventory_id = i.inventory_id
    GROUP BY f.film_id, f.title
)
SELECT film_id, title, nombre_locations
FROM compteurs
WHERE nombre_locations > (SELECT AVG(nombre_locations) FROM compteurs)
ORDER BY nombre_locations DESC, title;

\echo '=== Exercice 4.7 - EXISTS et NOT EXISTS ==='
-- Tache 1
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
WHERE NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    JOIN film_category fc ON fc.film_id = fa.film_id
    JOIN category c ON c.category_id = fc.category_id
    WHERE fa.actor_id = a.actor_id
      AND c.name = 'Horror'
)
ORDER BY a.actor_id;

-- Tache 2
SELECT f.film_id, f.title
FROM film f
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
    WHERE i.film_id = f.film_id
      AND r.customer_id = 1
)
ORDER BY f.title;

\echo '=== Modeles analytiques avances ==='
WITH revenus_journaliers AS (
    SELECT payment_date::date AS jour, SUM(amount) AS total_jour
    FROM payment
    GROUP BY payment_date::date
)
SELECT
    jour,
    total_jour,
    SUM(total_jour) OVER (
        ORDER BY jour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_cumule,
    SUM(total_jour) OVER (
        PARTITION BY date_trunc('month', jour)
        ORDER BY jour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumul_mensuel
FROM revenus_journaliers
ORDER BY jour;

WITH cohortes AS (
    SELECT customer_id, date_trunc('month', create_date)::date AS mois_cohorte
    FROM customer
), activite AS (
    SELECT
        co.mois_cohorte,
        date_trunc('month', r.rental_date)::date AS mois_activite,
        COUNT(DISTINCT r.customer_id) AS clients_actifs
    FROM cohortes co
    JOIN rental r ON r.customer_id = co.customer_id
    GROUP BY co.mois_cohorte, date_trunc('month', r.rental_date)
), tailles AS (
    SELECT mois_cohorte, COUNT(*) AS taille_cohorte
    FROM cohortes
    GROUP BY mois_cohorte
)
SELECT
    a.mois_cohorte,
    a.mois_activite,
    a.clients_actifs,
    t.taille_cohorte,
    ROUND(100.0 * a.clients_actifs / NULLIF(t.taille_cohorte, 0), 2) AS retention_pct
FROM activite a
JOIN tailles t USING (mois_cohorte)
ORDER BY a.mois_cohorte, a.mois_activite;

\connect blogapp
\echo '=== Tableau de bord BlogApp corrige pour le schema francais ==='

\echo '--- Croissance des utilisateurs ---'
WITH RECURSIVE mois AS (
    SELECT date_trunc('month', MIN(cree_le))::date AS mois
    FROM utilisateurs
    UNION ALL
    SELECT (mois + INTERVAL '1 month')::date
    FROM mois
    WHERE mois < date_trunc('month', CURRENT_DATE)::date
), inscriptions AS (
    SELECT date_trunc('month', cree_le)::date AS mois, COUNT(*) AS nouveaux
    FROM utilisateurs
    GROUP BY date_trunc('month', cree_le)
)
SELECT
    m.mois,
    COALESCE(i.nouveaux, 0) AS nouveaux_utilisateurs,
    SUM(COALESCE(i.nouveaux, 0)) OVER (
        ORDER BY m.mois ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS utilisateurs_cumules
FROM mois m
LEFT JOIN inscriptions i USING (mois)
ORDER BY m.mois;

\echo '--- Meilleurs auteurs sans multiplication des vues par les commentaires ---'
WITH stats_posts AS (
    SELECT
        u.user_id,
        u.username,
        COUNT(p.post_id) AS total_posts,
        COUNT(p.post_id) FILTER (WHERE p.statut = 'publie') AS posts_publies,
        COALESCE(SUM(p.compteur_vues) FILTER (WHERE p.statut = 'publie'), 0) AS total_vues,
        MAX(p.publie_le) FILTER (WHERE p.statut = 'publie') AS derniere_publication
    FROM utilisateurs u
    LEFT JOIN posts p ON p.user_id = u.user_id
    GROUP BY u.user_id, u.username
), stats_commentaires AS (
    SELECT p.user_id, COUNT(c.comment_id) AS total_commentaires
    FROM posts p
    LEFT JOIN commentaires c ON c.post_id = p.post_id
    GROUP BY p.user_id
), auteurs AS (
    SELECT
        sp.*,
        COALESCE(sc.total_commentaires, 0) AS total_commentaires
    FROM stats_posts sp
    LEFT JOIN stats_commentaires sc USING (user_id)
)
SELECT
    username,
    posts_publies,
    total_vues,
    total_commentaires,
    ROUND(total_vues::numeric / NULLIF(posts_publies, 0), 1) AS vues_moyennes,
    ROUND(total_commentaires::numeric / NULLIF(posts_publies, 0), 1) AS commentaires_moyens,
    derniere_publication,
    DENSE_RANK() OVER (ORDER BY posts_publies DESC) AS rang_posts
FROM auteurs
WHERE posts_publies > 0
ORDER BY posts_publies DESC, total_vues DESC;

\echo '--- Performance des posts ---'
WITH metriques AS (
    SELECT
        p.post_id,
        p.titre,
        u.username AS auteur,
        p.compteur_vues,
        COUNT(c.comment_id) AS nombre_commentaires,
        extract(epoch FROM (CURRENT_TIMESTAMP - p.publie_le)) / 86400.0 AS jours_depuis_publication
    FROM posts p
    JOIN utilisateurs u ON u.user_id = p.user_id
    LEFT JOIN commentaires c ON c.post_id = p.post_id
    WHERE p.statut = 'publie'
    GROUP BY p.post_id, u.username
)
SELECT
    titre,
    auteur,
    compteur_vues,
    nombre_commentaires,
    round(jours_depuis_publication, 2) AS jours_depuis_publication,
    round(compteur_vues / GREATEST(jours_depuis_publication, 1), 2) AS vues_par_jour,
    PERCENT_RANK() OVER (ORDER BY compteur_vues) AS percentile_vues,
    NTILE(10) OVER (ORDER BY compteur_vues DESC) AS decile_popularite
FROM metriques
ORDER BY compteur_vues DESC;

\echo '--- Comparaison des categories, agregations separees ---'
WITH stats_posts AS (
    SELECT
        c.category_id,
        c.nom,
        COUNT(p.post_id) AS nombre_posts,
        COALESCE(SUM(p.compteur_vues), 0) AS total_vues,
        AVG(p.compteur_vues) AS moyenne_vues
    FROM categories c
    LEFT JOIN posts p
      ON p.category_id = c.category_id
     AND p.statut = 'publie'
    GROUP BY c.category_id, c.nom
), stats_commentaires AS (
    SELECT p.category_id, COUNT(cm.comment_id) AS total_commentaires
    FROM posts p
    LEFT JOIN commentaires cm ON cm.post_id = p.post_id
    WHERE p.statut = 'publie'
    GROUP BY p.category_id
), combine AS (
    SELECT
        sp.*,
        COALESCE(sc.total_commentaires, 0) AS total_commentaires
    FROM stats_posts sp
    LEFT JOIN stats_commentaires sc USING (category_id)
)
SELECT
    nom AS categorie,
    nombre_posts,
    total_vues,
    ROUND(moyenne_vues, 1) AS moyenne_vues,
    total_commentaires,
    ROUND(100.0 * nombre_posts / NULLIF(SUM(nombre_posts) OVER (), 0), 2) AS pct_posts,
    RANK() OVER (ORDER BY total_vues DESC) AS rang_vues
FROM combine
ORDER BY total_vues DESC, categorie;

\echo '--- Popularite des tags ---'
WITH usage_tags AS (
    SELECT
        t.tag_id,
        t.nom,
        COUNT(p.post_id) AS utilisation_totale,
        COUNT(p.post_id) FILTER (
            WHERE p.publie_le > CURRENT_DATE - INTERVAL '30 days'
        ) AS utilisation_recente,
        AVG(p.compteur_vues) AS moyenne_vues
    FROM tags t
    LEFT JOIN post_tags pt ON pt.tag_id = t.tag_id
    LEFT JOIN posts p
      ON p.post_id = pt.post_id
     AND p.statut = 'publie'
    GROUP BY t.tag_id, t.nom
)
SELECT
    nom AS tag,
    utilisation_totale,
    utilisation_recente,
    ROUND(moyenne_vues, 1) AS moyenne_vues,
    ROUND(100.0 * utilisation_recente / NULLIF(utilisation_totale, 0), 1) AS score_tendance,
    NTILE(5) OVER (ORDER BY utilisation_totale DESC) AS niveau_popularite
FROM usage_tags
WHERE utilisation_totale > 0
ORDER BY utilisation_totale DESC, tag;

\echo '=== Defis LAB 04 ==='
-- 1. Cohortes mensuelles et retention par activite de publication.
WITH cohortes AS (
    SELECT user_id, date_trunc('month', cree_le)::date AS mois_cohorte
    FROM utilisateurs
), activite AS (
    SELECT
        c.mois_cohorte,
        date_trunc('month', p.cree_le)::date AS mois_activite,
        COUNT(DISTINCT p.user_id) AS auteurs_actifs
    FROM cohortes c
    JOIN posts p ON p.user_id = c.user_id
    GROUP BY c.mois_cohorte, date_trunc('month', p.cree_le)
), tailles AS (
    SELECT mois_cohorte, COUNT(*) AS taille
    FROM cohortes
    GROUP BY mois_cohorte
)
SELECT
    a.mois_cohorte,
    a.mois_activite,
    a.auteurs_actifs,
    t.taille,
    ROUND(100.0 * a.auteurs_actifs / NULLIF(t.taille, 0), 2) AS retention_pct
FROM activite a
JOIN tailles t USING (mois_cohorte)
ORDER BY a.mois_cohorte, a.mois_activite;

-- 2. Commentaires recus dans les 24 heures.
SELECT
    p.post_id,
    p.titre,
    COUNT(c.comment_id) AS commentaires_24h
FROM posts p
JOIN commentaires c
  ON c.post_id = p.post_id
 AND c.cree_le >= p.publie_le
 AND c.cree_le < p.publie_le + INTERVAL '24 hours'
WHERE p.statut = 'publie'
GROUP BY p.post_id, p.titre
ORDER BY commentaires_24h DESC, p.post_id;

-- 3. Score d engagement = vues + 10 x commentaires.
WITH stats_posts AS (
    SELECT
        u.user_id,
        u.username,
        COALESCE(SUM(p.compteur_vues), 0) AS vues
    FROM utilisateurs u
    LEFT JOIN posts p ON p.user_id = u.user_id AND p.statut = 'publie'
    GROUP BY u.user_id, u.username
), stats_commentaires AS (
    SELECT p.user_id, COUNT(c.comment_id) AS commentaires
    FROM posts p
    LEFT JOIN commentaires c ON c.post_id = p.post_id
    WHERE p.statut = 'publie'
    GROUP BY p.user_id
), engagement AS (
    SELECT
        sp.user_id,
        sp.username,
        sp.vues,
        COALESCE(sc.commentaires, 0) AS commentaires
    FROM stats_posts sp
    LEFT JOIN stats_commentaires sc USING (user_id)
)
SELECT
    *,
    vues + 10 * commentaires AS score_engagement,
    RANK() OVER (ORDER BY vues + 10 * commentaires DESC) AS rang
FROM engagement
ORDER BY rang, user_id;

-- 4. Categories dont le nombre de posts baisse d un mois au suivant.
WITH bornes AS (
    SELECT date_trunc('month', MIN(cree_le)) AS debut,
           date_trunc('month', CURRENT_DATE) AS fin FROM posts
), mois AS (
    SELECT generate_series(debut, fin, INTERVAL '1 month') AS mois FROM bornes
), mensuel AS (
    SELECT
        c.category_id,
        c.nom,
        m.mois::date AS mois,
        COUNT(p.post_id) AS nombre_posts
    FROM categories c
    CROSS JOIN mois m
    LEFT JOIN posts p ON p.category_id = c.category_id
        AND p.cree_le >= m.mois AND p.cree_le < m.mois + INTERVAL '1 month'
    GROUP BY c.category_id, c.nom, m.mois
), comparaison AS (
    SELECT
        *,
        LAG(nombre_posts) OVER (PARTITION BY category_id ORDER BY mois) AS mois_precedent
    FROM mensuel
)
SELECT nom, mois, nombre_posts, mois_precedent
FROM comparaison
WHERE nombre_posts < mois_precedent
ORDER BY mois, nom;

-- 5. Co-occurrence des tags.
SELECT
    t1.nom AS tag_1,
    t2.nom AS tag_2,
    COUNT(*) AS nombre_posts_communs
FROM post_tags pt1
JOIN post_tags pt2
  ON pt2.post_id = pt1.post_id
 AND pt2.tag_id > pt1.tag_id
JOIN tags t1 ON t1.tag_id = pt1.tag_id
JOIN tags t2 ON t2.tag_id = pt2.tag_id
GROUP BY t1.tag_id, t1.nom, t2.tag_id, t2.nom
ORDER BY nombre_posts_communs DESC, tag_1, tag_2;
