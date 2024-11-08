#!/bin/bash

# Liste des types de branches acceptés – histoire de garder tout propre et structuré
BRANCHES_VALIDES=("feature" "fix" "chore" "update" "hotfix" "release")

# Petit menu pour sélectionner le type de branche. Ça évite d’avoir à tout taper à la main.
select_type_branche() {
  echo "Sélectionnez le type de branche :"
  select type in "${BRANCHES_VALIDES[@]}"; do
    # Si l'utilisateur choisit quelque chose, on passe à la suite
    if [[ -n "$type" ]]; then
      TYPE_BRANCHE=$type
      break
    else
      # Au cas où l'utilisateur se trompe, on lui redonne une chance
      echo "Sélection invalide. Veuillez essayer à nouveau."
    fi
  done
}

# On appelle le menu pour choisir le type de branche
select_type_branche

# Demande à l'utilisateur de renseigner les infos pour la branche et le commit
read -p "Entrez le nom de la fonctionnalité : " NOM_FONCTIONNALITE
read -p "Entrez le message de commit : " MESSAGE_COMMIT

# Construction du nom de la branche en combinant type et nom de fonctionnalité
BRANCHE_NOM="$TYPE_BRANCHE/$NOM_FONCTIONNALITE"

# Juste pour s'assurer que tout est en ordre avant de se lancer
if [[ ! " ${BRANCHES_VALIDES[@]} " =~ " ${TYPE_BRANCHE} " ]]; then
  echo "Erreur : Type de branche invalide. Types acceptés : ${BRANCHES_VALIDES[*]}."
  exit 1
fi

# On commence la magie avec Git

# D'abord, on s'assure d'être sur `develop`
echo "Basculement sur la branche develop..."
git checkout develop || { echo "Erreur : impossible de changer vers develop"; exit 1; }

# On met à jour `develop` pour être à jour avec le remote, juste au cas où
echo "Mise à jour de develop..."
git pull origin develop || { echo "Erreur : impossible de mettre à jour develop"; exit 1; }

# Création de la nouvelle branche pour notre fonctionnalité
echo "Création de la branche $BRANCHE_NOM..."
git checkout -b $BRANCHE_NOM || { echo "Erreur : impossible de créer la branche $BRANCHE_NOM"; exit 1; }

# On ajoute les modifications et les valide avec le message fourni
echo "Ajout des modifications et validation..."
git add . || { echo "Erreur : impossible d'ajouter les modifications"; exit 1; }
git commit -m "$MESSAGE_COMMIT" || { echo "Erreur : impossible de valider les changements"; exit 1; }

# On pousse la nouvelle branche sur le remote pour que tout le monde puisse y accéder
echo "Poussée de la branche $BRANCHE_NOM vers le dépôt distant..."
git push -u origin $BRANCHE_NOM || { echo "Erreur : impossible de pousser la branche $BRANCHE_NOM"; exit 1; }

# Retour sur `develop` pour la fusion de la fonctionnalité
echo "Basculement sur develop pour fusionner $BRANCHE_NOM..."
git checkout develop || { echo "Erreur : impossible de changer vers develop"; exit 1; }
git merge --no-ff $BRANCHE_NOM || { echo "Erreur : échec de la fusion avec $BRANCHE_NOM"; exit 1; }

# On pousse `develop` avec la nouvelle fonctionnalité intégrée
echo "Poussée de develop vers le dépôt distant..."
git push origin develop || { echo "Erreur : impossible de pousser develop"; exit 1; }

# On passe sur `main` pour y intégrer les changements de `develop`
echo "Basculement sur main pour fusionner develop..."
git checkout main || { echo "Erreur : impossible de changer vers main"; exit 1; }

# Mise à jour de `main` pour récupérer les dernières modifications du dépôt
echo "Mise à jour de main..."
git pull origin main || { echo "Erreur : impossible de mettre à jour main"; exit 1; }

# Fusionne `develop` dans `main` pour finaliser l'intégration
echo "Fusion de develop dans main..."
git merge --no-ff develop || { echo "Erreur : échec de la fusion avec develop"; exit 1; }

# On envoie `main` sur le dépôt distant, et voilà, c'est officiel !
echo "Poussée de main vers le dépôt distant..."
git push origin main || { echo "Erreur : impossible de pousser main"; exit 1; }

# Nettoyage – on supprime la branche locale pour garder un dépôt propre
echo "Suppression de la branche locale $BRANCHE_NOM..."
git branch -d $BRANCHE_NOM || { echo "Erreur : impossible de supprimer la branche locale"; exit 1; }

# Et on fait pareil pour la branche distante
echo "Suppression de la branche distante $BRANCHE_NOM..."
git push origin --delete $BRANCHE_NOM || { echo "Erreur : impossible de supprimer la branche distante"; exit 1; }

# Et voilà, tout est en ordre !
echo "Processus complet terminé."

