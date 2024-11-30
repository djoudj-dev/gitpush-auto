#!/bin/bash

# Définir les codes de couleur ANSI et styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Liste des types de branches acceptés avec icônes
BRANCH_ICONS=(
    "${BOLD}✨ feature${NC}"
    "${BOLD}♻️ refactor${NC}"
    "${BOLD}🔧 fix${NC}"
    "${BOLD}🧹 chore${NC}"
    "${BOLD}⬆️ update${NC}"
    "${BOLD}🚨 hotfix${NC}"
    "${BOLD}🚀 release${NC}"
)

BRANCH_TYPES=("feature" "refactor" "fix" "chore" "update" "hotfix" "release")

# Fonction pour valider le nom de la branche
validate_branch_name() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}${BOLD}Erreur:${NC} Le nom de la fonctionnalité ne peut pas être vide."
        return 1
    fi
    if [[ ! $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo -e "${RED}${BOLD}Erreur:${NC} Le nom de la fonctionnalité doit commencer par une lettre ou un chiffre et ne contenir que des lettres, chiffres, tirets (-) et underscores (_)."
        return 1
    fi
    if [[ ${#name} -gt 50 ]]; then
        echo -e "${RED}${BOLD}Erreur:${NC} Le nom est trop long (maximum 50 caractères)."
        return 1
    fi
    return 0
}

# Vérification de la branche active
check_branch() {
    local current_branch=$(git symbolic-ref --short HEAD)
    echo -e "${YELLOW}${BOLD}Vous êtes actuellement sur la branche : ${BLUE}${current_branch}${NC}"

    if [[ "$current_branch" == "master" ]]; then
        echo -e "${RED}${BOLD}Erreur:${NC} Vous ne pouvez pas travailler directement sur master."
        exit 1
    fi

    if [[ "$current_branch" != "develop" ]]; then
        echo -e "${YELLOW}${BOLD}Voulez-vous changer pour la branche develop ?${NC}"
        select choice in "Oui" "Non"; do
            case $REPLY in
                1)
                    git checkout develop || {
                        echo -e "${RED}${BOLD}Erreur:${NC} impossible de basculer sur develop."
                        exit 1
                    }
                    break
                    ;;
                2)
                    echo -e "${RED}${BOLD}Abandon du script.${NC}"
                    exit 1
                    ;;
                *)
                    echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1 ou 2.${NC}"
                    ;;
            esac
        done
    fi
}

# Vérification des modifications locales non indexées
check_local_changes() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo -e "${RED}${BOLD}Erreur:${NC} Vous avez des modifications locales non validées."
        echo -e "${YELLOW}${BOLD}Voulez-vous les valider ou les remiser ?${NC}"
        echo -e "  ${GREEN}${BOLD}1) Valider${NC} - Ajouter et valider vos modifications dans un commit."
        echo -e "  ${YELLOW}${BOLD}2) Remiser${NC} - Enregistrer temporairement vos modifications pour y revenir plus tard."
        echo -e "  ${RED}${BOLD}3) Annuler le script${NC} - Quitter sans rien faire."
        
        # Lire le choix de l'utilisateur
        read -p "Votre choix (1, 2 ou 3) : " choice
        case $choice in
            1)
                echo -e "${YELLOW}${BOLD}Validation des modifications locales...${NC}"
                git add . || exit 1
                read -e -p "Entrez le message de commit : " MESSAGE_COMMIT
                git commit -m "$MESSAGE_COMMIT" || exit 1
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Remise des modifications locales...${NC}"
                git stash || exit 1
                ;;
            3)
                echo -e "${RED}${BOLD}Abandon du script.${NC}"
                exit 1
                ;;
            *)
                echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1, 2 ou 3.${NC}"
                check_local_changes # Relancer la fonction en cas de choix invalide
                ;;
        esac
    fi
}

# Sélectionner le type de branche
select_type_branche() {
    echo -e "${YELLOW}${BOLD}Sélectionnez le type de branche :${NC}"
    
    # Afficher les options avec leurs numéros
    for i in "${!BRANCH_ICONS[@]}"; do
        echo -e "  ${BOLD}$((i+1))) ${BRANCH_ICONS[i]}${NC}"
    done
    
    # Lire le choix de l'utilisateur
    while true; do
        read -p "Votre choix (1-${#BRANCH_ICONS[@]}) : " choice
        if [[ "$choice" =~ ^[1-7]$ ]] && (( choice >= 1 && choice <= ${#BRANCH_ICONS[@]} )); then
            TYPE_BRANCHE=${BRANCH_TYPES[$((choice-1))]}
            echo -e "${GREEN}${BOLD}Type sélectionné : ${BRANCH_ICONS[$((choice-1))]}${NC}"
            break
        else
            echo -e "${RED}${BOLD}Choix invalide. Veuillez entrer un nombre entre 1 et ${#BRANCH_ICONS[@]}.${NC}"
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
        echo -e "${YELLOW}${BOLD}Veuillez réessayer.${NC}"
    done
}

# Créer une branche fonctionnelle
create_branch() {
    local branch_name=$1
    echo -e "${GREEN}${BOLD}Création de la branche ${branch_name} à partir de develop...${NC}"
    git checkout develop || exit 1
    git pull origin develop || exit 1
    git checkout -b "$branch_name" || exit 1
}

# Valider et pousser les modifications
commit_and_push() {
    local branch_name=$1
    if ! git diff --quiet || ! git diff --cached --quiet; then
        read -e -p "Entrez le message de commit : " MESSAGE_COMMIT
        git add . || exit 1
        git commit -m "$MESSAGE_COMMIT" || exit 1
    fi
    git push -u origin "$branch_name" || exit 1
    echo -e "${GREEN}${BOLD}La branche ${branch_name} a été poussée avec succès.${NC}"
}

# Fusionner dans develop
merge_to_develop() {
    local branch_name=$1
    echo -e "${YELLOW}${BOLD}Fusion de ${branch_name} dans develop...${NC}"
    git checkout develop || exit 1
    git pull origin develop || exit 1
    git merge --no-ff "$branch_name" || exit 1
    git push origin develop || exit 1
    echo -e "${GREEN}${BOLD}Fusion réussie.${NC}"
}

# Supprimer une branche locale et distante après fusion
delete_branch() {
    local branch_name=$1
    echo -e "${YELLOW}${BOLD}Suppression de la branche locale ${branch_name}...${NC}"
    git branch -d "$branch_name" || {
        echo -e "${YELLOW}${BOLD}Aucune modification détectée dans ${branch_name}. Suppression forcée.${NC}"
        git branch -D "$branch_name"
    }
    echo -e "${GREEN}${BOLD}Branche locale supprimée avec succès.${NC}"

    # Suppression de la branche distante
    echo -e "${YELLOW}${BOLD}Suppression de la branche distante ${branch_name}...${NC}"
    git push origin --delete "$branch_name" || {
        echo -e "${RED}${BOLD}Erreur : impossible de supprimer la branche distante ${branch_name}.${NC}"
    }
    echo -e "${GREEN}${BOLD}Branche distante ${branch_name} supprimée avec succès.${NC}"
}

# Script principal
check_branch
check_local_changes
select_type_branche
get_branch_name
BRANCHE_NOM="${TYPE_BRANCHE}/${NOM_FONCTIONNALITE}"

create_branch "$BRANCHE_NOM"
commit_and_push "$BRANCHE_NOM"
merge_to_develop "$BRANCHE_NOM"
delete_branch "$BRANCHE_NOM"

echo -e "${GREEN}${BOLD}Processus terminé avec succès. N'oubliez pas de créer une Pull Request sur GitHub si nécessaire.${NC}"
