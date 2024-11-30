#!/bin/bash

# Définir les codes de couleur ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_CYAN='\033[1;36m'

# Liste des types de branches acceptés
BRANCHES_VALIDES=("feature" "refactor" "fix" "chore" "update" "hotfix" "release")

# Fonction pour valider le nom de la branche
validate_branch_name() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Erreur: Le nom de la fonctionnalité ne peut pas être vide.${NC}"
        return 1
    fi
    if [[ ! $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo -e "${RED}Erreur: Le nom de la fonctionnalité doit commencer par une lettre ou un chiffre et ne contenir que des lettres, chiffres, tirets (-) et underscores (_)${NC}"
        return 1
    fi
    if [[ ${#name} -gt 50 ]]; then
        echo -e "${RED}Erreur: Le nom est trop long (maximum 50 caractères).${NC}"
        return 1
    fi
    return 0
}

# Supprimer la branche locale et distante après vérification
delete_branch() {
    local branch=$1

    # Vérifier si la branche est active dans le worktree principal
    local current_branch=$(git symbolic-ref --short HEAD)
    if [[ "$current_branch" == "$branch" ]]; then
        echo -e "${YELLOW}La branche ${branch} est active dans le worktree principal.${NC}"
        echo -e "${YELLOW}Bascule sur develop avant de supprimer la branche...${NC}"
        git checkout develop || {
            echo -e "${RED}Erreur : impossible de basculer sur develop.${NC}"
            exit 1
        }
    fi

    # Supprimer la branche locale
    echo -e "${YELLOW}Suppression de la branche locale ${branch}...${NC}"
    git branch -d "$branch" || {
        echo -e "${RED}Erreur : impossible de supprimer la branche locale ${branch}.${NC}"
        exit 1
    }
    echo -e "${GREEN}La branche locale ${branch} a été supprimée.${NC}"

    # Supprimer la branche distante
    echo -e "${YELLOW}Suppression de la branche distante ${branch}...${NC}"
    git push origin --delete "$branch" || {
        echo -e "${RED}Erreur : impossible de supprimer la branche distante ${branch}.${NC}"
        exit 1
    }
    echo -e "${GREEN}La branche distante ${branch} a été supprimée.${NC}"
}

# Sélectionner le type de branche
select_type_branche() {
    PS3=$'\n'"📌 Votre choix (1-${#BRANCHES_VALIDES[@]}) : "
    echo -e "${BLUE}Sélectionnez le type de branche :${NC}"

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
        echo -e "$i) ${BRANCH_ICONS[$branch]} ${branch}"
        ((i++))
    done

    while true; do
        read -p $'\n'"📌 Votre choix (1-${#BRANCHES_VALIDES[@]}) : " choice
        if [[ "$choice" =~ ^[1-${#BRANCHES_VALIDES[@]}]$ ]]; then
            TYPE_BRANCHE=${BRANCHES_VALIDES[$((choice-1))]}
            echo -e "${GREEN}Type sélectionné : ${TYPE_BRANCHE}${NC}"
            break
        else
            echo -e "${RED}Sélection invalide. Veuillez choisir un numéro entre 1 et ${#BRANCHES_VALIDES[@]}.${NC}"
        fi
    done
}

# Demander et valider le nom de la fonctionnalité
get_branch_name() {
    while true; do
        read -e -p "Entrez le nom de la fonctionnalité : " NOM_FONCTIONNALITE
        if validate_branch_name "$NOM_FONCTIONNALITE"; then
            break
        fi
        echo -e "${YELLOW}Veuillez réessayer.${NC}"
    done
}

# Création de la branche fonctionnelle
create_branch() {
    local branch_name=$1
    echo -e "${GREEN}Création de la branche ${branch_name} à partir de develop...${NC}"
    git checkout develop || {
        echo -e "${RED}Erreur : impossible de basculer sur develop.${NC}"
        exit 1
    }
    git pull origin develop || {
        echo -e "${RED}Erreur : impossible de mettre à jour develop.${NC}"
        exit 1
    }
    git checkout -b "$branch_name" || {
        echo -e "${RED}Erreur : impossible de créer la branche ${branch_name}.${NC}"
        exit 1
    }
}

# Validation des modifications
commit_and_push() {
    local branch_name=$1
    read -e -p "Entrez le message de commit : " MESSAGE_COMMIT
    git add . || { echo -e "${RED}Erreur : impossible d'ajouter les fichiers.${NC}"; exit 1; }
    git commit -m "$MESSAGE_COMMIT" || { echo -e "${RED}Erreur : impossible de valider les modifications.${NC}"; exit 1; }
    git push -u origin "$branch_name" || { echo -e "${RED}Erreur : impossible de pousser la branche.${NC}"; exit 1; }
    echo -e "${GREEN}La branche ${branch_name} a été poussée avec succès.${NC}"
}

# Fusion dans develop
merge_to_develop() {
    local branch_name=$1
    echo -e "${YELLOW}Fusion de ${branch_name} dans develop...${NC}"
    git checkout develop || {
        echo -e "${RED}Erreur : impossible de basculer sur develop.${NC}"
        exit 1
    }
    git pull origin develop || {
        echo -e "${RED}Erreur : impossible de mettre à jour develop.${NC}"
        exit 1
    }
    git merge --no-ff "$branch_name" || {
        echo -e "${RED}Erreur : impossible de fusionner ${branch_name} dans develop.${NC}"
        exit 1
    }
    git push origin develop || {
        echo -e "${RED}Erreur : impossible de pousser develop après la fusion.${NC}"
        exit 1
    }
    echo -e "${GREEN}Fusion réussie.${NC}"
}

# Script principal
select_type_branche
get_branch_name
BRANCHE_NOM="${TYPE_BRANCHE}/${NOM_FONCTIONNALITE}"
create_branch "$BRANCHE_NOM"
commit_and_push "$BRANCHE_NOM"
merge_to_develop "$BRANCHE_NOM"
delete_branch "$BRANCHE_NOM"

echo -e "${GREEN}Processus terminé avec succès.${NC}"
