
# 📦 Utilisation de gitpush – Automatisation du Processus Git

Pour rendre le processus de gestion des branches, des commits, et des fusions plus rapide et plus organisé, j’ai créé un alias appelé gitpush. Cet alias utilise un script (git-push.sh) pour automatiser toutes les étapes de mon flux de travail Git. Voici comment tout fonctionne, étape par étape !

# 🏁 Pour commencer créer un alias
```bash
nano ~/.zshrc
```
```bash
alias gitpush='/chemin/vers/git-push.sh'
```
```bash
source ~/.zshrc
```

# 🚀 Comment utiliser l'alias gitpush
```bash
gitpush
```
Lancer l'alias gitpush dans le terminal est très simple ! Assurez-vous d'être dans le bon répertoire de votre projet, puis tapez simplement : gitpush (ou comme vous l'aurez nommer)

# 🎯 Étapes du script git-push.sh

Le script git-push.sh va vous guider à travers plusieurs étapes pour organiser votre travail dans Git. Voici chaque étape, expliquée simplement.

## 1) Sélection du Type de Branche

- Le script commence par vous demander de choisir le type de branche dans une liste (par exemple : "feature" "fix" "chore" "update" "hotfix" "release").Vous sélectionnez le type de branche avec les flèches, puis appuyez sur Entrée pour confirmer.
#### 💡 Pourquoi ? Cela assure que toutes les branches suivent une convention de nommage, pour un projet bien organisé.

## 2) Entrez les Détails de la Branche et du Commit
```bash
"Entrez le nom de la fonctionnalité : "
```

```bash
"Entrez le message de commit : "
```
-  Ensuite, le script vous demande deux informations :
- Nom de la fonctionnalité – C'est un nom descriptif pour la branche.
- Message de commit – Une courte description de ce que vous avez modifié.
#### 💡 Pourquoi ? Pour que tout le monde comprenne ce que fait chaque modification.

## 3) Création d'une Nouvelle Branche

```bash
git checkout -b $BRANCHE_NOM
```
- Le script crée une nouvelle branche avec le nom formaté, comme feature/nouvelle_fonction.
- Il se place ensuite automatiquement sur cette branche pour que vous puissiez y travailler.
#### 💡 Pourquoi ? Avoir une branche pour chaque fonctionnalité ou correction permet de garder le projet principal propre.

## 4) Ajout et Validation des Modifications
```bash
git add .
```

```bash
git commit -m "$MESSAGE_COMMIT"
```
- Le script ajoute tous les fichiers modifiés et les valide avec votre message de commit.
- Cela correspond à ranger tous vos changements dans un dossier avec une petite note pour se rappeler de ce qui a été modifié.
#### 💡 Pourquoi ? Cela permet d'avoir un historique clair et détaillé des modifications.

## 5) Envoi de la Nouvelle Branche vers GitHub
```bashgit push -u origin $BRANCHE_NOM
```
- Une fois le commit prêt, le script envoie votre branche sur GitHub.
- Ainsi, vos collègues ou collaborateurs peuvent voir et examiner vos changements.
#### 💡 Pourquoi ? Travailler en collaboration est plus facile quand chacun peut accéder aux modifications en temps réel.

## 6) Fusion de la Branche dans develop
```bash
git checkout develop
```

```bash
git merge --no-ff $BRANCHE_NOM
```

```bash
git push origin develop
```
- Le script revient ensuite sur develop (la branche de développement principale) et y fusionne votre branche de fonctionnalité.
- Puis, il pousse develop vers GitHub pour garder tout le monde à jour.
#### 💡 Pourquoi ? La branche develop est l'endroit où tout le travail en cours est combiné avant d’être validé dans la branche principale.

## 7) Fusion de develop dans main
```bash
git checkout main
```

```bash
git pull origin main
```

```bash
git merge --no-ff develop
```

```bash
git push origin main
```
- Ensuite, le script passe sur la branche main (la branche finale) et y fusionne tout le travail qui est dans develop.
- Puis, il pousse main sur GitHub pour que la version officielle soit mise à jour.
#### 💡 Pourquoi ? La branche main représente la version la plus stable et complète du projet. C'est ce que le public voit.

## 8) Nettoyage des Branches
```bash
git branch -d $BRANCHE_NOM
```

```bash
git push origin --delete $BRANCHE_NOM
```
- Pour garder le dépôt propre, le script supprime la branche locale et la branche distante une fois qu'elles ne sont plus nécessaires.
#### 💡 Pourquoi ? Cela empêche les branches de s'accumuler et de créer des désordres.

# 🎉 Processus Terminé
**À la fin, le script affiche :**

```bash
"Processus complet terminé."
```

# 📝 Résumé Visuel
**Étape	Action	Résultat**

1️⃣ Sélection du type	Choisir le type de branche	Assure une convention de nommage

2️⃣ Nom & Message	Saisir le nom et le message	Description claire de la fonctionnalité

3️⃣ Création de branche	Créer une nouvelle branche	Structure les nouvelles fonctionnalités

4️⃣ Commit des changements	Ajouter et valider les modifications	Enregistre tout avec une description

5️⃣ Push sur GitHub	Envoyer la branche de fonctionnalité	La branche est visible pour tous

6️⃣ Fusion dans develop	Revenir sur develop et fusionner	Met à jour la branche de développement

7️⃣ Fusion dans main	Passer à main et y intégrer develop	Mise à jour de la version principale

8️⃣ Nettoyage	Supprimer les branches locales et distantes	Évite les branches inutiles

**En utilisant gitpush, vous n'avez plus à vous soucier des étapes techniques de Git. Ce script rend le processus rapide, clair et collaboratif.**


