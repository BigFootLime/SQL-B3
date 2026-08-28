# Préparer la soutenance

Le [PowerPoint](Presentation_SQL_B3.pptx) contient 11 diapositives et des notes. Le déroulé ci-dessous dure environ 18 min 30, questions comprises. Il sert de repère ; expliquer les requêtes avec ses propres mots.

| Diapositives | Durée | Point à montrer |
|---|---|---|
| 1–2 | 2 min | Besoin, choix de Coffee, vrais textes et normalisation des références absentes |
| 3 | 1 min 30 | Pourquoi `post_ids` existe et pourquoi la clé de `posts` inclut la date |
| 4–5 | 3 min | FTS, poids titre/corps, trigrammes, filtres et pagination |
| 6 | 2 min | RLS sous un rôle lecteur, données privées et séparation du cache |
| 7 | 1 min 30 | Exemple Scholar et compteur de réponses |
| 8–9 | 3 min | Mesures, cache applicatif, comparaison avant/après et limites |
| 10 | 3 min | Démo dans psql |
| 11 | 30 s + 1 min 30 | Limites puis questions |

## Avant de commencer

Relancer la suite indiquée dans le README sur l'instance de TP. Vérifier les lignes `OK` et ouvrir le terminal à la racine du dépôt. Les scripts d'installation recréent les bases ; les exécuter avant la présentation, pas au milieu de la démonstration.

Ouvrir une console :

```sh
docker compose exec -w /workspace postgres psql -U labuser -d stackexchange
```

Pour répéter toute la démonstration, saisir `\i sql/demo.sql`. Pour l'oral, exécuter ses quatre blocs l'un après l'autre. Le script ouvre une transaction puis l'annule : les recherches de démonstration ne restent pas dans les journaux.

## Les quatre moments de la démo

1. Rechercher `coffee brewing`, puis répéter. Montrer `cache_hit` dans `search_log`. Le temps peut changer selon le poste ; expliquer ce que le cache évite au second appel.
2. Rechercher `espressso` avec `smart_search`. Montrer la colonne `match_type`, puis la recherche filtrée par tag et score. Afficher une suggestion `cof`.
3. Passer à `tenant_reader` et au tenant 1. Le regroupement par `tenant_id` ne montre que ce tenant. Passer au tenant 2 et vérifier le changement. Expliquer que le serveur applicatif devra fixer ce contexte après authentification.
4. Revenir au rôle initial et afficher les métriques, tendances et `dashboard_posts`. La fenêtre de vingt ans est volontaire : le dump est ancien. Les statistiques de visites de la vue fédérée sont simulées comme demandé dans l'exercice 9.6.

Pour démontrer les trois visibilités et le cache après changement de confidentialité, lancer séparément `\i tests/projet.sql`. Ce test crée des posts temporaires dans deux tenants, passe sous les rôles lecteur/modérateur/admin et annule ses données à la fin. Les assertions expliquent les résultats attendus.

## Questions à préparer

- **Pourquoi GIN et GiST ?** Le vecteur FTS sert à retrouver des lexèmes. L'index trigramme sert aux ressemblances de texte. Expliquer les requêtes qui utilisent chacun, puis montrer un plan.
- **Pourquoi ne pas utiliser seulement une clé primaire `id` dans `posts` ?** La contrainte unique d'une table partitionnée doit couvrir la clé de partition. `post_ids` fournit l'identité globale et les références des autres tables.
- **Comment vérifier RLS ?** Changer réellement de rôle. Une lecture en superutilisateur ne démontre pas l'isolation. Vérifier aussi le cache et les accès directs aux partitions.
- **Est-ce que toutes les recherches prennent moins de 100 ms ?** Le résultat annoncé est un 95e percentile sur le scénario décrit. Le maximum et les limites du test sont publiés dans le rapport.
- **Pourquoi les tendances récentes sont-elles vides ?** Le dump est historique. Une plage longue sert à examiner ses données, sans inventer de nouveaux événements.
- **Pourquoi les vues ne doivent-elles pas être additionnées après la jointure des commentaires ?** Un post apparaît une fois par commentaire. Il faut agréger chaque relation à la bonne granularité avant de les joindre.
- **Quel a été le piège du badge Scholar ?** C'est la question qui change quand une réponse est acceptée ; le badge revient à l'auteur de la réponse.

Le support prépare l'explication, mais ne remplace pas la compréhension des fonctions et des tests.
