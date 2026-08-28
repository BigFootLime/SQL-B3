# Correspondance avec les consignes

Les énoncés viennent de Teams, dans `B3 RPI ISITECH LYON / 2025-2026 / Dev / SQL / TPs`. Le cours est accessible sur [Formation PostgreSQL ISITECH B3](https://sql-pv.vercel.app/1). Les PDF restent sur Teams ; ce dépôt contient les réponses et leurs données d'exécution.

Les solutions déjà présentes dans [labs-postgresql-01-05](https://github.com/BigFootLime/labs-postgresql-01-05) ont été reprises, corrigées et complétées. Les dates de dépôt des LAB 01 à 04 sont le 24 août 2026, celle du LAB 05 le 25 août. Le jeudi et le vendredi de cette semaine sont les **27 et 28 août 2026**. Les dates d'auteur et de commit des six étapes de reprise ont été réattribuées à ces deux journées le 14 septembre 2026. La reprise et les vérifications ont été effectuées le 14 septembre ; leurs rapports portent cette date.

## LAB 01 à 04

| Consigne | Réponse |
|---|---|
| LAB 01, installation et connexion | `docker-compose.yml`, `scripts/run_labs.ps1`, `scripts/run_docker.sh`, vérifications de version/base/utilisateur dans `sql/01_lab01_environment.sql` |
| LAB 01, exercices 1.4 à 1.8 | Création de `test_users`, insertions, modifications, suppression, transactions COMMIT/ROLLBACK, nettoyage dans le même fichier |
| LAB 01, défi notes | Table `notes`, relation auteur, insertions et jointure dans le même fichier |
| LAB 02, Pagila et exercices 2.1/2.2 | Import dans `sql/00_pagila.sql`, description des tables et des clés étrangères dans `sql/02_lab02_ddl_dml.sql` |
| LAB 02, exercices 2.3 à 2.5 | Tables tags/commentaires, contraintes vérifiées et ALTER TABLE |
| LAB 02, exercices 2.6 à 2.8 | INSERT, UPDATE et DELETE Pagila ; opérations d'entraînement annulées après affichage des résultats |
| LAB 02, BlogApp et défis | Schéma complet, données d'exemple, dix posts supplémentaires, publication des brouillons, suppression des tags inutilisés et UPSERT |
| LAB 03, exercices 3.1 à 3.8 | `sql/03_lab03_queries.sql` : SELECT, WHERE, tri, pagination, jointures, agrégations, GROUP BY/HAVING et fonctions intégrées |
| LAB 03, BlogApp et cinq défis | Profil, liste/détail/recherche de posts, analyses, posts récents, posts commentés, auteurs sans publication, moyenne de commentaires et tags fréquents |
| LAB 04, exercices 4.1 à 4.7 | `sql/04_lab04_queries.sql` : CTE, récursivité, rangs, LAG/LEAD, agrégats fenêtre, sous-requêtes et EXISTS |
| LAB 04, tableaux de bord et cinq défis | Croissance, auteurs, catégories, tags ; cohortes, commentaires en 24 h, engagement, baisse mensuelle et co-occurrence des tags |

Le schéma BlogApp du LAB 02 utilise des noms français. Les requêtes des LAB suivants ont été adaptées à ce schéma. Les agrégats de vues et de commentaires sont calculés séparément pour éviter de multiplier les vues lors d'une jointure. Les mois sans publication comptent pour zéro dans l'analyse des baisses.

Dans Pagila, la langue française porte l'identifiant 5. L'archivage des locations conserve les références des paiements : il ne déplace que les locations sans paiement et utilise `DELETE ... RETURNING` dans la même instruction que l'insertion en archive. Un cas temporaire démontre ce traitement. Certaines dates littérales de l'énoncé ne recoupent pas celles du dump ; les adaptations sont signalées dans les scripts.

## LAB 05

Les numéros ci-dessous sont ceux des parties du LAB 05. Tout le schéma et les fonctions se trouvent dans `projet_final.sql` ; les fichiers de tests les exécutent après installation.

| Partie ou exercice | Réalisation | Vérification |
|---|---|---|
| 1, données Stack Exchange | Dump Coffee, convertisseur XML/CSV, import de huit tables | Empreintes SHA-256, comptages, clés étrangères |
| 2.8, moteur FTS | `search_posts`, vecteur pondéré, dictionnaires, pagination et extraits | Recherche anglaise, racinisation française, vecteurs remplis |
| 3.5, recherche intelligente | `smart_search`, correspondances exactes puis trigrammes | Une recherche `espressso` retourne des résultats flous |
| 3, chiffrement | `user_secrets`, chiffrement et déchiffrement avec pgcrypto | Égalité vérifiée à l'installation, accès lecteur refusé |
| 4.7, partitions de votes | Renommage en `votes_old`, migration vers douze mois de 2023 et une partition par défaut | Nombre de votes inchangé, treize partitions, EXPLAIN d'un mois |
| 5, fonctions et triggers | Réputation, thread, compteur de réponses, audit et gestion d'erreur | Exécution dans le script, compteurs et déplacements dans les tests |
| 5.8, badges | Scholar, Nice Answer, Popular Question, Supporter et Critic | Attribution sur INSERT/UPDATE, auteur de réponse acceptée, idempotence |
| 6.8, facettes JSONB | `faceted_search`, tags, score, dates, réponse acceptée et métadonnées | Filtres, mauvais types JSON et paramètres inconnus |
| 7.8, optimisation | Index, VACUUM/ANALYZE, sous-requêtes puis agrégations avec jointures | `tests/optimisation.sql`, résultats comparés par EXCEPT ALL et plans complets |
| 8.8, multi-tenancy | `tenants`, contexte de session, rôles lecteur/modérateur/admin, RLS | Tests sous les trois rôles, visibilité privée et séparation des caches |
| 9.6, fédération | `file_fdw`, CSV de tags enrichis, statistiques simulées et `dashboard_posts` | Jointure effective et rafraîchissement de la vue |
| 10, projet final | Recherche avancée, suggestions, cache, tendances, questions montantes, dashboard et `search_analytics` | Tests fonctionnels et benchmark exécutables |

Les exemples de connexion à un serveur PostgreSQL distant ou MySQL sont des éléments du cours. L'exercice de fédération 9.6 demande un CSV et autorise une table locale de statistiques simulées : c'est cette configuration qui est livrée, sans serveur distant fictif.

## Livrables du projet

| Livrable demandé | Fichier |
|---|---|
| Script SQL unique | [`projet_final.sql`](../projet_final.sql) |
| Architecture et choix techniques | [`PROJET.md`](PROJET.md) |
| Guide des fonctions et exemples | [`PROJET.md`](PROJET.md) et [`sql/demo.sql`](../sql/demo.sql) |
| Temps, débit, tailles, statistiques et avant/après | [`PERFORMANCE.md`](../rapports/PERFORMANCE.md), `benchmark.json`, `optimisation.json` |
| Bilan des tests | [`VALIDATION.md`](../rapports/VALIDATION.md) |
| Support oral de 15 à 20 minutes | [`Presentation_SQL_B3.pptx`](Presentation_SQL_B3.pptx), 11 diapositives avec notes |
| Démonstration et préparation aux questions | [`DEMONSTRATION.md`](DEMONSTRATION.md) |

La présentation est préparée. La soutenance et les réponses aux questions en direct restent à réaliser par l'étudiant.
