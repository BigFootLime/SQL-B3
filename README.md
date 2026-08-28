# SQL B3 - PostgreSQL

TP de Keenan MARTIN, B3 RPI ISITECH Lyon. Ce dépôt reprend le travail déjà présent dans [labs-postgresql-01-05](https://github.com/BigFootLime/labs-postgresql-01-05), puis le complète et le vérifie contre les énoncés.

Les supports ont été retrouvés dans Teams : B3 RPI ISITECH LYON > 2025-2026 > Dev > SQL. Les LAB 01 à 04 sont datés du 24 août 2026 ; le LAB 05 du 25 août. La semaine de cours est donc celle du 24 au 28 août 2026. Le 14 septembre 2026, les dates d'auteur et de commit des six étapes de reprise ont été réattribuées aux 27 et 28 août pour les rattacher aux journées de cours. Elles ne constituent pas une preuve de travail réalisé ces jours-là. Les rapports conservent leurs dates réelles de mesure.

- `sql/` : exercices des LAB 01 à 04 et import des données.
- `projet_final.sql` : LAB 05 et moteur de recherche Stack Exchange.
- `tests/` : vérifications fonctionnelles.
- `docs/` : correspondance avec les consignes, architecture et démonstration.
- `rapports/` : résultats des vérifications et mesures de performance.

Les bases de travail sont `blogapp_lab`, `pagila`, `blogapp` et `stackexchange`. Les scripts d'installation recréent ces bases : utiliser exclusivement l'environnement de TP dédié fourni ici.

## Exécution

Prérequis : Git, Python 3 et Docker Compose. Les CSV Coffee sont fournis dans une archive de 3,5 Mo dont les empreintes sont vérifiées automatiquement.

Créer un fichier `.env` non versionné contenant `POSTGRES_PASSWORD=un_mot_de_passe_local`, puis lancer depuis la racine :

```powershell
./scripts/run_labs.ps1
```

Sous Linux ou macOS avec Docker : `bash scripts/run_docker.sh`.

L'instance du TP écoute uniquement sur `127.0.0.1:55436`. Le script arrête l'exécution à la première erreur et range les journaux dans `rapports/logs/`. Pour ouvrir une console :

```sh
docker compose exec postgres psql -U labuser -d stackexchange
```

Avec PostgreSQL déjà installé, créer une **instance séparée**, initialisée avec `labuser`, charger `pg_stat_statements` au démarrage et créer `blogapp_lab`. Définir `PGHOST`, `PGPORT` et `PGUSER`, puis lancer `bash scripts/run_labs.sh`. Les vérifications locales ont utilisé PostgreSQL 18.6 sous Ubuntu. Le workflow GitHub exécute la même suite avec PostgreSQL 16.

La [documentation du projet](docs/PROJET.md), le [suivi des consignes](docs/COUVERTURE.md), le [rapport de performance](rapports/PERFORMANCE.md), le [bilan des tests](rapports/VALIDATION.md), le [déroulé oral](docs/DEMONSTRATION.md) et la [présentation PowerPoint](docs/Presentation_SQL_B3.pptx) complètent les scripts.

## Sources

- Énoncés : `LAB_01_Configuration_Environnement.pdf`, `LAB_02.pdf`, `LAB_03.pdf`, `LAB_04.pdf`, `LAB_05.pdf` et `AVERTISSEMENT-LLM.pdf` dans Teams.
- Cours en ligne : [Formation PostgreSQL ISITECH B3](https://sql-pv.vercel.app/1), retrouvé dans `Support/support_en_ligne.url`. Le dossier contient aussi `slides-export.pdf`, daté du 27 août.
- Pagila : [devrimgunduz/pagila](https://github.com/devrimgunduz/pagila), version 3.1.0. Schéma et données conservés dans `sources/pagila`, avec leur licence.
- Coffee Stack Exchange : [dump Stack Exchange](https://archive.org/details/stackexchange). Les données brutes ne sont pas versionnées.
