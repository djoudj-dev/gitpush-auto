#!/bin/bash

# Définir les codes de couleur ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Liste des types de branches acceptés – histoire de garder tout propre et structuré
BRANCHES_VALIDES=("feature" "fix" "chore" "update" "hotfix" "release")

# Petit menu pour sélectionner le type de branche. Ça évite d’avoir à tout taper à la main.
select_type_branche() {
  echo -e "${BLUE}Sélectionnez le type de branche :${NC}"
  select type in "${BRANCHES_VALIDES[@]}"; do
    # Si l'utilisateur choisit quelque chose, on passe à la suite
    if [[ -n "$type" ]]; then
      TYPE_BRANCHE=$type
      break
    else
      # Au cas où l'utilisateur se trompe, on lui redonne une chance
      echo -e "${RED}Sélection invalide. Veuillez essayer à nouveau.${NC}"
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
  echo -e "${RED}Erreur : Type de branche invalide. Types acceptés : ${BRANCHES_VALIDES[*]}.${NC}"
  exit 1
fi

# On commence la magie avec Git

# D'abord, on s'assure d'être sur `develop`
echo -e "${GREEN}Basculement sur la branche develop...${NC}"
git checkout develop || { echo -e "${RED}Erreur : impossible de changer vers develop${NC}"; exit 1; }

# On met à jour `develop` pour être à jour avec le remote, juste au cas où
echo -e "${GREEN}Mise à jour de develop...${NC}"
git pull origin develop || { echo -e "${RED}Erreur : impossible de mettre à jour develop${NC}"; exit 1; }

# Création de la nouvelle branche pour notre fonctionnalité
echo -e "${GREEN}Création de la branche $BRANCHE_NOM...${NC}"
git checkout -b $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de créer la branche $BRANCHE_NOM${NC}"; exit 1; }

# On ajoute les modifications et les valide avec le message fourni
echo -e "${GREEN}Ajout des modifications et validation...${NC}"
git add . || { echo -e "${RED}Erreur : impossible d'ajouter les modifications${NC}"; exit 1; }
git commit -m "$MESSAGE_COMMIT" || { echo -e "${RED}Erreur : impossible de valider les changements${NC}"; exit 1; }

# On pousse la nouvelle branche sur le remote pour que tout le monde puisse y accéder
echo -e "${GREEN}Poussée de la branche $BRANCHE_NOM vers le dépôt distant...${NC}"
git push -u origin $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de pousser la branche $BRANCHE_NOM${NC}"; exit 1; }

# Retour sur `develop` pour la fusion de la fonctionnalité
echo -e "${GREEN}Basculement sur develop pour fusionner $BRANCHE_NOM...${NC}"
git checkout develop || { echo -e "${RED}Erreur : impossible de changer vers develop${NC}"; exit 1; }
git merge --no-ff $BRANCHE_NOM || { echo -e "${RED}Erreur : échec de la fusion avec $BRANCHE_NOM${NC}"; exit 1; }

# On pousse `develop` avec la nouvelle fonctionnalité intégrée
echo -e "${GREEN}Poussée de develop vers le dépôt distant...${NC}"
git push origin develop || { echo -e "${RED}Erreur : impossible de pousser develop${NC}"; exit 1; }

# On passe sur `main` pour y intégrer les changements de `develop`
echo -e "${GREEN}Basculement sur main pour fusionner develop...${NC}"
git checkout main || { echo -e "${RED}Erreur : impossible de changer vers main${NC}"; exit 1; }

# Mise à jour de `main` pour récupérer les dernières modifications du dépôt
echo -e "${GREEN}Mise à jour de main...${NC}"
git pull origin main || { echo -e "${RED}Erreur : impossible de mettre à jour main${NC}"; exit 1; }

# Fusionne `develop` dans `main` pour finaliser l'intégration
echo -e "${GREEN}Fusion de develop dans main...${NC}"
git merge --no-ff develop || { echo -e "${RED}Erreur : échec de la fusion avec develop${NC}"; exit 1; }

# On envoie `main` sur le dépôt distant, et voilà, c'est officiel !
echo -e "${GREEN}Poussée de main vers le dépôt distant...${NC}"
git push origin main || { echo -e "${RED}Erreur : impossible de pousser main${NC}"; exit 1; }

# Nettoyage – on supprime la branche locale pour garder un dépôt propre
echo -e "${GREEN}Suppression de la branche locale $BRANCHE_NOM...${NC}"
git branch -d $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de supprimer la branche locale${NC}"; exit 1; }

# Et on fait pareil pour la branche distante
echo -e "${GREEN}Suppression de la branche distante $BRANCHE_NOM...${NC}"
git push origin --delete $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de supprimer la branche distante${NC}"; exit 1; }

# Et voilà, tout est en ordre !
echo -e "${GREEN}Processus complet terminé.${NC}"
