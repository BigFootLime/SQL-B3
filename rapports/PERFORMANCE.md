# Rapport de performance

Mesures de recherche : 2026-09-14T11:00:19.796788+02:00. Comparaison avant/après : 2026-09-14T10:59:31.443238+02:00.

## Conditions de mesure

Serveur : PostgreSQL 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0, 64-bit. Instance de TP dédiée sous Ubuntu/WSL, sur le poste local. Base de 53 MB, contenant 4525 posts et 19909 votes Coffee Stack Exchange.

`tests/benchmark.sql` alterne un appel sans cache applicatif et le même appel avec cache. Il répète trente fois chacune des recherches `coffee`, `espresso grinder`, `brewing temperature`, `espressso` et `cold brew`, soit 150 appels par scénario. Chaque appel a retourné des résultats. Le cache de pages PostgreSQL reste chaud ; ce test ne mesure pas un démarrage à froid.

Les durées viennent de `clock_timestamp()` côté serveur et comprennent le calcul des résultats, le cache applicatif et la journalisation. La suppression du cache avant un appel est hors chronométrage. Le débit ci-dessous est calculé comme 1 000 / durée moyenne : il correspond aux appels séquentiels mesurés, sans latence réseau ni utilisateurs concurrents.

## Recherche

| Scénario | Appels | Moyenne (ms) | Médiane (ms) | P95 (ms) | Maximum (ms) | Appels/s séquentiels |
|---|---:|---:|---:|---:|---:|---:|
| Sans cache applicatif | 150 | 28,734 | 6,867 | 65,603 | 547,513 | 34,8 |
| Avec cache applicatif | 150 | 0,13 | 0,109 | 0,193 | 0,737 | 7667,54 |

Le P95 respecte l’objectif de 100 ms sur ce jeu et ce scénario. Le maximum sans cache dépasse ce seuil : le résultat ne garantit donc pas que chaque recherche sera sous 100 ms. Les limites du jeu, de la machine et de la charge séquentielle empêchent de généraliser le débit à un service en production.

## Comparaison avant/après

La version initiale compte les commentaires et les votes avec des sous-requêtes corrélées. La version réécrite sélectionne les candidats, agrège les votes par post, retient les cent premiers, puis compte les commentaires de ces résultats. Les index sur les relations post/commentaires et post/votes accompagnent les jointures.

Les deux versions portent sur la dernière année du dump, dont la date maximale est `2024-03-28T11:06:14.09`. La condition littérale basée sur `NOW()` ne retourne aucune question récente. Cette adaptation explicite permet de comparer 53 lignes ; leur égalité a été vérifiée dans les deux sens avec `EXCEPT ALL`.

| Version | Répétitions | Moyenne (ms) | Médiane (ms) |
|---|---:|---:|---:|
| avant | 30 | 2,192 | 2,06 |
| apres | 30 | 1,558 | 1,455 |

Sur ces répétitions, la durée moyenne diminue de **28,94 %**. Une prise de plan ajoute son propre coût d'instrumentation ; ses temps ci-dessous ne remplacent pas les moyennes précédentes.

| Plan instrumenté | Exécution (ms) | Shared hit blocks | Shared read blocks |
|---|---:|---:|---:|
| avant | 3,397 | 2688 | 0 |
| apres | 3,008 | 1904 | 0 |

Les arbres complets `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` sont conservés dans [optimisation.json](optimisation.json). Les blocs du tableau sont ceux du nœud racine ; les additionner à ceux des enfants les compterait plusieurs fois.

## Tables et index

Les vingt relations les plus volumineuses sont exportées avec `pg_size_pretty`. `table_et_toast` inclut les données annexes de la table ; la colonne index est séparée. La table `votes_old` est conservée pour vérifier la migration du LAB 4.7. Les relations d’une même famille sont séparées par partition.

| Relation | Table et TOAST | Index |
|---|---:|---:|
| `posts_2015` | 4128 kB | 3536 kB |
| `posts_2016` | 2488 kB | 2248 kB |
| `posts_2017` | 1920 kB | 1816 kB |
| `posts_2018` | 1680 kB | 1632 kB |
| `users` | 2672 kB | 592 kB |
| `posts_2019` | 1176 kB | 1176 kB |
| `votes_default` | 1032 kB | 1112 kB |
| `posts_2020` | 984 kB | 1080 kB |
| `posts_2021` | 1040 kB | 1008 kB |
| `votes_old` | 1048 kB | 896 kB |
| `posts_2022` | 880 kB | 976 kB |
| `comments` | 1440 kB | 224 kB |
| `badges` | 1128 kB | 424 kB |
| `posts_2023` | 544 kB | 640 kB |
| `search_cache` | 624 kB | 32 kB |
| `posts_2024` | 224 kB | 392 kB |
| `post_ids` | 232 kB | 280 kB |
| `dashboard_posts` | 256 kB | 56 kB |
| `post_tags` | 144 kB | 120 kB |
| `posts_default` | 16 kB | 200 kB |

## pg_stat_statements

Les statistiques ci-dessous concernent uniquement la base courante. Les commandes sont normalisées par PostgreSQL. Elles proviennent de l’exécution du projet et des vérifications, sous plusieurs rôles ; elles ne représentent pas les 300 échantillons internes du bloc PL/pgSQL du benchmark. Ces derniers sont chronométrés séparément dans la table temporaire `bench`.

| Requête normalisée | Appels | Moyenne (ms) | Lignes |
|---|---:|---:|---:|
| `SELECT assert_true((SELECT COUNT(*) FROM advanced_search($1))=$2,$3)` | 4 | 13,087 | 4 |
| `DO $$ DECLARE i INTEGER; q TEXT; start_time timestamptz; n INTEGER; queries TEXT[] := ARRAY['coffee','espresso grinder','brewing temperature','espressso','cold brew']; BEGIN -- Cinq requêtes distinctes, répétées 30 fois. Cache applicatif vide puis -- rempli. Le cache de pages PostgreSQL reste chaud dans les deux cas. FOR i IN 1..150 LOOP q := queries[1 + (i-1)%5]; DELETE FROM search_cache WHERE scope=search_scope(); start_time := clock_timestamp(); SELECT COUNT(*) INTO n FROM advanced_search(q); INSERT INTO bench VALUES ('sans_cache_applicatif',extract(epoch FROM clock_timestamp()-start_time)*1000,n); start_time := clock_timestamp(); SELECT COUNT(*) INTO n FROM advanced_search(q); INSERT INTO bench VALUES ('avec_cache_applicatif',extract(epoch FROM clock_timestamp()-start_time)*1000,n); END LOOP; END $$` | 2 | 4394,492 | 0 |
| `SELECT assert_true(EXISTS(SELECT FROM advanced_search($1,$2) WHERE post_id=$3), $4)` | 2 | 17,149 | 2 |
| `SELECT * FROM advanced_search($1)` | 2 | 256,375 | 40 |
| `SELECT COUNT(*) FROM advanced_search($1)` | 1 | 0,193 | 1 |

## Choix et pistes à tester

- Le GIN du vecteur FTS et le GiST trigramme correspondent à deux recherches différentes. Leurs rôles sont détaillés dans [PROJET.md](../docs/PROJET.md).
- Garder les statistiques à jour avec ANALYZE après un chargement important. Le TP exécute VACUUM/ANALYZE et affiche les paramètres mémoire utiles sans modifier une instance existante.
- Mesurer sur un dump plus gros avant de conclure que le partitionnement ou le BRIN apporte un gain. Un filtre de date permet de vérifier l’élagage avec EXPLAIN.
- Tester une distribution réaliste de recherches et une charge concurrente avant de dimensionner le service. Ajouter les temps réseau et client à ce protocole serveur.
- Pour un usage prolongé, prévoir le nettoyage des journaux et suggestions et une politique de rétention. Le cache expire après cinq minutes et ses résultats sont invalidés à la modification des posts ou tags.

## Reproduire

Lancer la suite depuis le README. Elle régénère `benchmark.json` et `optimisation.json`. Les valeurs varieront avec le poste, la version de PostgreSQL et son état. Ce rapport et le PowerPoint sont des instantanés des mesures datées ci-dessus. Le workflow GitHub répète la suite sur PostgreSQL 16 et affiche son propre bilan dans le résumé du job ; il ne remplace pas silencieusement ces mesures locales.
