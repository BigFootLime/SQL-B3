# Bilan des vérifications

Vérifications réalisées le 14 septembre 2026 sur une instance PostgreSQL 18.6 isolée sous Ubuntu/WSL. La base PostgreSQL préexistante du poste n'a pas été utilisée. Docker Desktop n'a pas démarré correctement sur ce poste ; l'exécution avec Docker Compose est vérifiée sur GitHub Actions avec PostgreSQL 16.

| Ensemble | Résultat |
|---|---|
| Empreintes des huit CSV | Vérifiées avant extraction |
| LAB 01, import Pagila, LAB 02, LAB 03 et LAB 04 | Exécution complète, arrêt sur erreur activé |
| Installation du projet | Import, partitions, fonctions, triggers, vues et droits exécutés |
| Tests fonctionnels | 38 vérifications explicites réussies |
| Comparaison avant/après | 53 lignes identiques, trente répétitions par version |
| Benchmark | 150 appels sans cache applicatif et 150 avec ; résultats non vides |
| Démonstration | Les quatre blocs de `sql/demo.sql` exécutés ; transaction annulée |

Le [workflow PostgreSQL 16](https://github.com/BigFootLime/SQL-B3/actions/workflows/sql.yml) rejoue la suite à chaque push. Un [premier passage complet réussi](https://github.com/BigFootLime/SQL-B3/actions/runs/34824997931) valide aussi l'environnement Docker. Les exécutions suivantes sont rattachées au commit correspondant dans GitHub.

Les erreurs attendues des exercices de contraintes sont interceptées et vérifiées. Elles ne sont pas ignorées par un mode de poursuite global. Les scripts tournent avec `ON_ERROR_STOP`. Les tests du projet ajoutent des données temporaires, changent de rôle et terminent par ROLLBACK.

## Contrôles fonctionnels réussis

- import des 4525 posts Coffee
- migration de tous les votes
- 12 partitions mensuelles et une partition par defaut
- vecteurs FTS remplis
- tolere une faute de frappe
- pagination limitee
- pages sans doublons
- cache utilise au second appel
- date_range respecte
- score minimum respecte
- tag absent exclut les resultats
- autocompletion
- tableau de bord temps reel
- recherche vide refusee
- page invalide refusee
- type JSON invalide refuse
- filtre inconnu refuse
- compteur mis a jour apres rattachement
- Scholar attribue a auteur de reponse acceptee
- Nice Answer
- Popular Question
- Supporter sur insertion vote
- Critic sur modification vote
- attributions de badges idempotentes
- recherche francaise avec racinisation
- langue inconnue : repli anglais
- filtre de metadonnees JSONB
- lecteur voit seulement le post public de son tenant
- changement de tenant ne reutilise pas le mauvais cache
- resultat du tenant 2
- proprietaire voit aussi son post prive
- acces direct aux partitions refuse
- acces aux secrets refuse
- moderateur voit les trois visibilites du tenant
- administrateur voit les deux tenants
- changement de visibilite invalide le cache
- suppression reponse decremente le compteur
- jointure avec le CSV via file_fdw

## Portée de la vérification

Les requêtes des LAB ont été exécutées sur leurs données ; elles ne disposent pas chacune d'un résultat attendu automatisé. Les assertions du projet visent les cas fonctionnels et les défauts corrigés. Le benchmark mesure une charge séquentielle locale ; aucune charge concurrente de production n'a été simulée.

La présentation PowerPoint comporte onze diapositives, des notes et un graphique éditable. Son package, sa géométrie, ses polices, les données du graphique et son import ont été contrôlés ; chaque diapositive a été rendue et inspectée visuellement. Aucun test d'ouverture dans Microsoft PowerPoint n'est revendiqué. La soutenance en direct reste à effectuer.
