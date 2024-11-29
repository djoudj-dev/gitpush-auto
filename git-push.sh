#!/bin/bash

# Définir les codes de couleur ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Définir des couleurs supplémentaires
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_MAGENTA='\033[1;35m'
LIGHT_CYAN='\033[1;36m'

# Liste des types de branches acceptés
BRANCHES_VALIDES=("feature" "refactor" "fix" "chore" "update" "hotfix" "release")

# Fonction pour valider le nom de la branche
validate_branch_name() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Erreur: Le nom de la fonctionnalité ne peut pas être vide${NC}"
        return 1
    fi
    if [[ ! $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo -e "${RED}Erreur: Le nom de la fonctionnalité doit commencer par une lettre ou un chiffre et ne contenir que des lettres, chiffres, tirets (-) et underscores (_)${NC}"
        return 1
    fi
    if [[ ${#name} -gt 50 ]]; then
        echo -e "${RED}Erreur: Le nom est trop long (maximum 50 caractères)${NC}"
        return 1
    fi
    return 0
}

# Vérifier si la branche actuelle est master et empêcher toute action
check_if_master() {
    current_branch=$(git symbolic-ref --short HEAD)
    if [[ "$current_branch" == "master" ]]; then
        echo -e "${RED}Erreur : Vous ne pouvez pas effectuer de push directement sur la branche 'master'.${NC}"
        echo -e "${YELLOW}Veuillez d'abord vous positionner sur une autre branche (par exemple, 'develop').${NC}"
        exit 1
    fi
}

# Sélectionner le type de branche
select_type_branche() {
  PS3=$'\n'"📌 Votre choix (1-${#BRANCHES_VALIDES[@]}) : "
  echo -e "${BLUE}Sélectionnez le type de branche :${NC}"

  declare -A BRANCH_COLORS=(
    ["feature"]="${CYAN}"
    ["refactor"]="${MAGENTA}"
    ["fix"]="${LIGHT_GREEN}"
    ["chore"]="${LIGHT_YELLOW}"
    ["update"]="${LIGHT_BLUE}"
    ["hotfix"]="${RED}"
    ["release"]="${LIGHT_CYAN}"
  )

  declare -A BRANCH_ICONS=(
    ["feature"]="✨"
    ["refactor"]="♻️"
    ["fix"]="🔧"
    ["chore"]="🧹"
    ["update"]="⬆️"
    ["hotfix"]="🚨"
    ["release"]="🚀"
  )

  local i=1
  for branch in "${BRANCHES_VALIDES[@]}"; do
    echo -e "$i) ${BRANCH_ICONS[$branch]} ${BRANCH_COLORS[$branch]}$branch${NC}"
    ((i++))
  done

  while true; do
    read -p $'\n'"📌 Votre choix (1-${#BRANCHES_VALIDES[@]}) : " choice
    if [[ "$choice" =~ ^[1-7]$ ]]; then
      TYPE_BRANCHE=${BRANCHES_VALIDES[$((choice-1))]}
      echo -e "Type sélectionné : ${BRANCH_ICONS[$TYPE_BRANCHE]} ${BRANCH_COLORS[$TYPE_BRANCHE]}$TYPE_BRANCHE${NC}"
      break
    else
      echo -e "${RED}Sélection invalide. Veuillez choisir un numéro entre 1 et ${#BRANCHES_VALIDES[@]}.${NC}"
    fi
  done
}

# Demander à l'utilisateur sur quelle branche il est
current_branch=$(git symbolic-ref --short HEAD)
echo -e "${BLUE}Vous êtes actuellement sur la branche : $current_branch${NC}"

# Vérifier si l'utilisateur est sur master et empêcher de continuer
check_if_master

# Demander si l'utilisateur veut rester sur la branche actuelle ou changer
echo -e "1) Rester sur la branche actuelle"
echo -e "2) Changer de branche"

read -p "Veuillez choisir une option (1 ou 2) : " choix

if [[ "$choix" == "1" ]]; then
    # Si l'utilisateur choisit de rester sur la branche actuelle, continuer
    echo -e "${GREEN}Vous êtes resté sur la branche $current_branch.${NC}"
    BRANCHE_TRAVAIL=$current_branch
elif [[ "$choix" == "2" ]]; then
    # Si l'utilisateur choisit de changer de branche, demander le nom de la branche
    read -p "Sur quelle branche souhaitez-vous passer pour créer la fonctionnalité (autre que master) ? : " BRANCHE_TRAVAIL

    # Si la branche est vide ou master, demander à nouveau
    while [[ -z "$BRANCHE_TRAVAIL" || "$BRANCHE_TRAVAIL" == "master" ]]; do
        echo -e "${RED}Erreur: Vous devez spécifier une branche autre que 'master'.${NC}"
        read -p "Entrez une branche valide pour la fonctionnalité (ex: develop, staging, etc.) : " BRANCHE_TRAVAIL
    done

    # Basculement vers la nouvelle branche
    echo -e "${GREEN}Basculement sur la branche $BRANCHE_TRAVAIL...${NC}"
    git checkout $BRANCHE_TRAVAIL || { echo -e "${RED}Erreur : impossible de changer vers $BRANCHE_TRAVAIL${NC}"; exit 1; }
fi

# Demander le nom de la fonctionnalité
read -p "Entrez le nom de la fonctionnalité : " NOM_FONCTIONNALITE

# Appel de la fonction pour choisir le type de branche
select_type_branche

# Valider le nom de la branche de fonctionnalité
while true; do
    read -e -p "Entrez le nom de la fonctionnalité : " NOM_FONCTIONNALITE
    if validate_branch_name "$NOM_FONCTIONNALITE"; then
        break
    fi
    echo -e "${YELLOW}Veuillez réessayer.${NC}"
done

# Demander le message du commit
read -e -p "Entrez le message de commit : " MESSAGE_COMMIT

# Construction du nom de la branche
BRANCHE_NOM="$TYPE_BRANCHE/$NOM_FONCTIONNALITE"

# Création de la nouvelle branche
echo -e "${GREEN}Création de la branche $BRANCHE_NOM...${NC}"
git checkout -b $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de créer la branche $BRANCHE_NOM${NC}"; exit 1; }

# Ajouter et valider les changements
echo -e "${GREEN}Ajout des modifications et validation...${NC}"
git add . || { echo -e "${RED}Erreur : impossible d'ajouter les modifications${NC}"; exit 1; }
git commit -m "$MESSAGE_COMMIT" || { echo -e "${RED}Erreur : impossible de valider les changements${NC}"; exit 1; }

# Pousser la branche vers le dépôt distant sans fusionner
echo -e "${GREEN}Poussée de la branche $BRANCHE_NOM vers le dépôt distant...${NC}"
git push -u origin $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de pousser la branche $BRANCHE_NOM${NC}"; exit 1; }

# Message sur la PR
echo -e "${YELLOW}Pour finaliser, veuillez créer une Pull Request pour que la branche soit revue avant fusion.${NC}"

# Nettoyage – suppression de la branche locale
echo -e "${GREEN}Suppression de la branche locale $BRANCHE_NOM...${NC}"
git branch -d $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de supprimer la branche locale${NC}"; exit 1; }

# Suppression de la branche distante si nécessaire
echo -e "${GREEN}Suppression de la branche distante $BRANCHE_NOM...${NC}"
git push origin --delete $BRANCHE_NOM || { echo -e "${RED}Erreur : impossible de supprimer la branche distante${NC}"; exit 1; }

# Processus terminé
echo -e "${GREEN}Processus complet terminé. Veuillez maintenant créer une Pull Request pour intégrer votre fonctionnalité.${NC}"
