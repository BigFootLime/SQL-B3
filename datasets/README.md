# Données Coffee Stack Exchange

`coffee-csv.zip` contient les huit CSV utilisés pour les tests. `scripts/prepare_data.py` contrôle les empreintes SHA-256 du manifeste avant extraction. Le projet se relance ainsi depuis un clone, sans dépendre de fichiers restés sur un autre ordinateur.

Source : [Coffee Stack Exchange](https://coffee.stackexchange.com), archive publique `coffee.stackexchange.com.7z` du [Stack Exchange Data Dump](https://archive.org/details/stackexchange). La conversion XML vers CSV est disponible dans `sql/import_stackexchange_xml.py`.

Les textes et noms d'auteurs proviennent des contributions des utilisateurs de Coffee Stack Exchange. Les identifiants et les associations auteur/post sont conservés. Un post se retrouve à l'adresse `https://coffee.stackexchange.com/questions/ID` et un auteur à `https://coffee.stackexchange.com/users/ID`. Les textes relèvent des licences CC BY-SA applicables à leur date de publication, décrites dans [les conditions de licence de Stack Exchange](https://stackoverflow.com/help/licensing). Cette conversion change le format et normalise les références absentes, sans revendiquer la propriété des contenus.

Le convertisseur a ajouté un utilisateur neutre pour une référence absente du dump et écarté 2 219 votes dont le post n'existe plus. Les CSV contiennent 11 595 utilisateurs, 4 525 posts, 4 985 commentaires, 19 909 votes, 14 615 badges, 114 tags et 2 947 associations post/tag. Le compte neutre n'est pas une personne supplémentaire observée et ses dates sont des valeurs techniques de remplacement.

Le jeu est historique. Les tendances sur les 30 derniers jours peuvent donc être vides. La comparaison de performance utilise explicitement la dernière année présente dans les données, sans modifier leurs dates.
