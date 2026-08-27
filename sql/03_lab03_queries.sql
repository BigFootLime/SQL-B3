\set ON_ERROR_STOP on
\pset pager off
\timing on

\connect pagila
\echo '=== LAB 03 - SELECT, filtres, tris, jointures et agregations ==='

\echo '=== Exercice 3.1 - SELECT de base ==='
-- Tache 1
SELECT title, release_year, rental_rate
FROM film
ORDER BY film_id;

-- Tache 2
SELECT
    concat(first_name, ' ', last_name) AS nom_complet,
    upper(email) AS email_majuscule
FROM customer
ORDER BY customer_id;

-- Tache 3
SELECT DISTINCT rating
FROM film
ORDER BY rating;

\echo '=== Exercice 3.2 - WHERE ==='
-- Tache 1
SELECT film_id, title, rating, rental_rate
FROM film
WHERE rating = 'R'
  AND rental_rate > 3.00
ORDER BY title;

-- Tache 2
SELECT customer_id, first_name, last_name, email
FROM customer
WHERE last_name ILIKE 's%'
ORDER BY last_name, first_name;

-- Tache 3
SELECT film_id, title, length, rating
FROM film
WHERE length BETWEEN 100 AND 120
  AND rating IN ('PG-13', 'R')
ORDER BY length, title;

\echo '=== Exercice 3.3 - tri et pagination ==='
-- Tache 1 : film_id departage les tarifs identiques.
SELECT film_id, title, rental_rate
FROM film
ORDER BY rental_rate DESC, film_id
LIMIT 10;

-- Tache 2 : page 3, 20 clients par page.
SELECT customer_id, first_name, last_name, email
FROM customer
ORDER BY last_name, first_name, customer_id
LIMIT 20 OFFSET 40;

-- Tache 3
SELECT film_id, title, length
FROM film
ORDER BY length DESC, film_id
LIMIT 5 OFFSET 1;

\echo '=== Exercice 3.4 - INNER JOIN ==='
-- Tache 1
SELECT f.title, c.name AS categorie
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
ORDER BY f.title;

-- Tache 2
SELECT
    p.payment_date,
    p.amount,
    concat(c.first_name, ' ', c.last_name) AS client
FROM customer c
JOIN payment p ON p.customer_id = c.customer_id
WHERE c.first_name = 'MARY'
  AND c.last_name = 'SMITH'
ORDER BY p.payment_date;

-- Tache 3
SELECT
    f.title,
    concat(a.first_name, ' ', a.last_name) AS acteur,
    c.name AS categorie
FROM film f
JOIN film_actor fa ON fa.film_id = f.film_id
JOIN actor a ON a.actor_id = fa.actor_id
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
ORDER BY f.title, a.last_name, a.first_name
LIMIT 20;

\echo '=== Exercice 3.5 - jointures externes ==='
-- Tache 1
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
LEFT JOIN film_actor fa ON fa.actor_id = a.actor_id
WHERE fa.actor_id IS NULL
ORDER BY a.actor_id;

-- Tache 2
SELECT c.category_id, c.name, COUNT(fc.film_id) AS nombre_films
FROM category c
LEFT JOIN film_category fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY nombre_films DESC, c.name;

\echo '=== Exercice 3.6 - fonctions d agregation ==='
-- Tache 1
SELECT
    SUM(amount) AS total,
    AVG(amount) AS moyenne,
    MIN(amount) AS minimum,
    MAX(amount) AS maximum
FROM payment;

-- Tache 2
SELECT COUNT(DISTINCT customer_id) AS clients_ayant_paye
FROM payment;

\echo '=== Exercice 3.7 - GROUP BY et HAVING ==='
-- Tache 1
SELECT c.name AS categorie, COUNT(fc.film_id) AS nombre_films
FROM category c
LEFT JOIN film_category fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY nombre_films DESC, c.name;

-- Tache 2
SELECT
    a.actor_id,
    concat(a.first_name, ' ', a.last_name) AS acteur,
    COUNT(fa.film_id) AS nombre_films
FROM actor a
JOIN film_actor fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING COUNT(fa.film_id) > 30
ORDER BY nombre_films DESC, acteur;

-- Tache 3 : le sujet demande 2007, mais le Pagila charge contient 2022.
SELECT MIN(payment_date) AS premier_paiement, MAX(payment_date) AS dernier_paiement
FROM payment;

SELECT
    date_trunc('month', payment_date)::date AS mois,
    SUM(amount) AS revenu_total
FROM payment
WHERE payment_date >= DATE '2007-01-01'
  AND payment_date < DATE '2008-01-01'
GROUP BY date_trunc('month', payment_date)
ORDER BY mois;

-- Version utile avec l annee reellement presente dans le dataset.
SELECT
    date_trunc('month', payment_date)::date AS mois,
    SUM(amount) AS revenu_total
FROM payment
GROUP BY date_trunc('month', payment_date)
ORDER BY mois;

\echo '=== Exercice 3.8 - fonctions integrees ==='
-- Tache 1
SELECT
    last_name || ', ' || first_name || ' (' || upper(email) || ')' AS contact
FROM customer
ORDER BY customer_id;

-- Tache 2 : calcul en secondes pour obtenir une vraie duree totale.
SELECT
    rental_id,
    rental_date,
    return_date,
    round(
        extract(epoch FROM (coalesce(return_date, CURRENT_TIMESTAMP) - rental_date))
        / 86400.0,
        2
    ) AS duree_jours
FROM rental
ORDER BY rental_id;

-- Tache 3
SELECT
    film_id,
    title,
    length,
    CASE
        WHEN length < 90 THEN 'Court'
        WHEN length <= 120 THEN 'Moyen'
        ELSE 'Long'
    END AS categorie_duree
FROM film
ORDER BY film_id;

\connect blogapp
\echo '=== Requetes d application BlogApp - schema francais du LAB 02 ==='

\echo '--- Profil utilisateur ---'
SELECT
    u.user_id,
    u.username,
    u.email,
    concat_ws(' ', u.prenom, u.nom) AS nom_complet,
    u.bio,
    u.cree_le AS membre_depuis,
    COUNT(p.post_id) AS total_posts,
    COUNT(p.post_id) FILTER (WHERE p.statut = 'publie') AS posts_publies,
    COALESCE(SUM(p.compteur_vues), 0) AS total_vues
FROM utilisateurs u
LEFT JOIN posts p ON p.user_id = u.user_id
WHERE u.username = 'alice'
GROUP BY u.user_id;

\echo '--- Liste paginee des posts publies ---'
SELECT
    p.post_id,
    p.titre,
    p.slug,
    p.extrait,
    p.publie_le,
    p.compteur_vues,
    u.username AS auteur,
    c.nom AS categorie,
    COUNT(cm.comment_id) FILTER (WHERE cm.est_approuve) AS nombre_commentaires
FROM posts p
JOIN utilisateurs u ON u.user_id = p.user_id
LEFT JOIN categories c ON c.category_id = p.category_id
LEFT JOIN commentaires cm ON cm.post_id = p.post_id
WHERE p.statut = 'publie'
  AND p.publie_le <= NOW()
GROUP BY p.post_id, u.username, c.nom
ORDER BY p.publie_le DESC, p.post_id DESC
LIMIT 10 OFFSET 0;

\echo '--- Detail d un post et ses tags ---'
SELECT
    p.post_id,
    p.titre,
    p.contenu,
    p.publie_le,
    p.compteur_vues,
    u.username AS auteur,
    concat_ws(' ', u.prenom, u.nom) AS nom_complet_auteur,
    c.nom AS categorie,
    array_remove(array_agg(DISTINCT t.nom ORDER BY t.nom), NULL) AS tags
FROM posts p
JOIN utilisateurs u ON u.user_id = p.user_id
LEFT JOIN categories c ON c.category_id = p.category_id
LEFT JOIN post_tags pt ON pt.post_id = p.post_id
LEFT JOIN tags t ON t.tag_id = pt.tag_id
WHERE p.slug = 'getting-started-postgresql'
  AND p.statut = 'publie'
GROUP BY p.post_id, u.user_id, c.nom;

SELECT
    cm.comment_id,
    cm.contenu,
    cm.cree_le,
    u.username,
    concat_ws(' ', u.prenom, u.nom) AS nom_commentateur
FROM commentaires cm
JOIN utilisateurs u ON u.user_id = cm.user_id
WHERE cm.post_id = (
    SELECT post_id FROM posts WHERE slug = 'getting-started-postgresql'
)
  AND cm.est_approuve
ORDER BY cm.cree_le, cm.comment_id;

\echo '--- Recherche, categorie et tag ---'
SELECT p.post_id, p.titre, p.slug, p.extrait, u.username AS auteur, p.publie_le
FROM posts p
JOIN utilisateurs u ON u.user_id = p.user_id
WHERE p.statut = 'publie'
  AND (p.titre ILIKE '%postgresql%' OR p.contenu ILIKE '%postgresql%')
ORDER BY p.publie_le DESC
LIMIT 20;

SELECT p.post_id, p.titre, p.slug, p.publie_le, u.username AS auteur
FROM posts p
JOIN utilisateurs u ON u.user_id = p.user_id
JOIN categories c ON c.category_id = p.category_id
WHERE c.slug = 'programmation'
  AND p.statut = 'publie'
ORDER BY p.publie_le DESC
LIMIT 20;

SELECT p.post_id, p.titre, p.slug, p.publie_le, u.username AS auteur
FROM posts p
JOIN utilisateurs u ON u.user_id = p.user_id
JOIN post_tags pt ON pt.post_id = p.post_id
JOIN tags t ON t.tag_id = pt.tag_id
WHERE t.slug = 'tutoriel'
  AND p.statut = 'publie'
ORDER BY p.publie_le DESC
LIMIT 20;

\echo '=== Requetes analytiques BlogApp ==='
SELECT
    (SELECT COUNT(*) FROM utilisateurs WHERE est_actif) AS utilisateurs_actifs,
    (SELECT COUNT(*) FROM posts WHERE statut = 'publie') AS posts_publies,
    (SELECT COUNT(*) FROM posts WHERE statut = 'brouillon') AS brouillons,
    (SELECT COUNT(*) FROM commentaires WHERE est_approuve) AS commentaires_approuves,
    (SELECT COALESCE(SUM(compteur_vues), 0) FROM posts) AS total_vues,
    (
        SELECT COUNT(DISTINCT user_id)
        FROM posts
        WHERE cree_le > CURRENT_DATE - INTERVAL '30 days'
    ) AS auteurs_actifs_30j;

SELECT
    u.user_id,
    u.username,
    COUNT(p.post_id) AS posts_publies,
    COALESCE(SUM(p.compteur_vues), 0) AS total_vues,
    ROUND(AVG(p.compteur_vues), 1) AS vues_moyennes,
    MAX(p.publie_le) AS derniere_publication
FROM utilisateurs u
JOIN posts p ON p.user_id = u.user_id
WHERE p.statut = 'publie'
GROUP BY u.user_id, u.username
ORDER BY posts_publies DESC, total_vues DESC
LIMIT 10;

SELECT
    p.post_id,
    p.titre,
    u.username AS auteur,
    p.compteur_vues,
    COUNT(c.comment_id) FILTER (WHERE c.est_approuve) AS commentaires_approuves,
    p.publie_le
FROM posts p
JOIN utilisateurs u ON u.user_id = p.user_id
LEFT JOIN commentaires c ON c.post_id = p.post_id
WHERE p.statut = 'publie'
GROUP BY p.post_id, u.username
ORDER BY p.compteur_vues DESC
LIMIT 20;

SELECT
    c.nom AS categorie,
    COUNT(p.post_id) AS nombre_posts,
    ROUND(
        100.0 * COUNT(p.post_id)
        / NULLIF((SELECT COUNT(*) FROM posts WHERE statut = 'publie'), 0),
        2
    ) AS pourcentage
FROM categories c
LEFT JOIN posts p
    ON p.category_id = c.category_id
   AND p.statut = 'publie'
GROUP BY c.category_id, c.nom
ORDER BY nombre_posts DESC, c.nom;

SELECT
    date_trunc('month', publie_le)::date AS mois,
    COUNT(*) AS nombre_posts
FROM posts
WHERE statut = 'publie'
  AND publie_le >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY date_trunc('month', publie_le)
ORDER BY mois;

SELECT
    t.nom AS tag,
    COUNT(pt.post_id) AS utilisation_calculee,
    t.compteur_utilisation
FROM tags t
LEFT JOIN post_tags pt ON pt.tag_id = t.tag_id
GROUP BY t.tag_id, t.nom, t.compteur_utilisation
ORDER BY utilisation_calculee DESC, t.nom
LIMIT 30;

\echo '=== Defis LAB 03 ==='
-- 1. Posts publies dans les 7 derniers jours avec plus de 100 vues.
SELECT post_id, titre, compteur_vues, publie_le
FROM posts
WHERE statut = 'publie'
  AND publie_le >= NOW() - INTERVAL '7 days'
  AND compteur_vues > 100
ORDER BY publie_le DESC;

-- 2. Cinq posts les plus commentes.
SELECT p.post_id, p.titre, COUNT(c.comment_id) AS nombre_commentaires
FROM posts p
LEFT JOIN commentaires c ON c.post_id = p.post_id
GROUP BY p.post_id, p.titre
ORDER BY nombre_commentaires DESC, p.post_id
LIMIT 5;

-- 3. Utilisateurs qui n ont jamais publie.
SELECT u.user_id, u.username
FROM utilisateurs u
WHERE NOT EXISTS (
    SELECT 1
    FROM posts p
    WHERE p.user_id = u.user_id
      AND p.statut = 'publie'
)
ORDER BY u.user_id;

-- 4. Nombre moyen de commentaires par post et categorie.
WITH commentaires_par_post AS (
    SELECT p.post_id, p.category_id, COUNT(c.comment_id) AS nombre_commentaires
    FROM posts p
    LEFT JOIN commentaires c ON c.post_id = p.post_id
    GROUP BY p.post_id, p.category_id
)
SELECT
    c.nom AS categorie,
    ROUND(AVG(cpp.nombre_commentaires), 2) AS moyenne_commentaires_par_post
FROM categories c
LEFT JOIN commentaires_par_post cpp ON cpp.category_id = c.category_id
GROUP BY c.category_id, c.nom
ORDER BY c.nom;

-- 5. Tags utilises dans plus de 5 posts.
SELECT t.tag_id, t.nom, COUNT(pt.post_id) AS nombre_posts
FROM tags t
JOIN post_tags pt ON pt.tag_id = t.tag_id
GROUP BY t.tag_id, t.nom
HAVING COUNT(pt.post_id) > 5
ORDER BY nombre_posts DESC, t.nom;

