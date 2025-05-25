#!/bin/bash

# Définir les codes de couleur ANSI et styles
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;39m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'
ORANGE='\033[38;5;214m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Détecter la branche principale (master ou main)
detect_main_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        echo "main" # Par défaut si aucune des deux n'existe
    fi
}

# Vérifier si la branche develop existe
check_develop_branch_exists() {
    git show-ref --verify --quiet refs/heads/develop
    return $?
}

# Créer la branche develop à partir de la branche principale
create_develop_branch() {
    local main_branch=$1
    echo -e "${YELLOW}${BOLD}Création de la branche develop à partir de ${BLUE}${main_branch}${NC}..."
    git checkout "$main_branch" || exit 1
    git pull origin "$main_branch" || exit 1
    git checkout -b develop || exit 1
    git push -u origin develop || exit 1
    echo -e "${GREEN}${BOLD}Branche develop créée avec succès.${NC}"
}

# Branche principale détectée
MAIN_BRANCH=$(detect_main_branch)
# Branche de base pour les nouvelles fonctionnalités (par défaut la branche principale)
BASE_BRANCH=$MAIN_BRANCH

# Liste des types de branches acceptés avec icônes
BRANCH_ICONS=(
    "${GREEN}${BOLD}🌟 feature${NC}"
    "${BLUE}${BOLD}🔄 refactor${NC}"
    "${RED}${BOLD}🛠️  fix${NC}"
    "${ORANGE}${BOLD}🧰 chore${NC}"
    "${CYAN}${BOLD}📦 update${NC}"
    "${MAGENTA}${BOLD}🚑 hotfix${NC}"
    "${GREEN}${BOLD}🚀 release${NC}"
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
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    echo -e "${YELLOW}${BOLD}Vous êtes actuellement sur la branche : ${BLUE}${current_branch}${NC}"

    # Vérifier si on est sur la branche principale (master ou main)
    if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
        echo -e "${RED}${BOLD}Erreur:${NC} Vous ne pouvez pas travailler directement sur la branche principale ($MAIN_BRANCH)."

        # Vérifier si la branche develop existe
        if ! check_develop_branch_exists; then
            echo -e "${YELLOW}${BOLD}La branche develop n'existe pas. Voulez-vous la créer ?${NC}"
            select choice in "Oui" "Non"; do
                case $REPLY in
                    1)
                        create_develop_branch "$MAIN_BRANCH"
                        current_branch="develop"
                        BASE_BRANCH="develop"
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
        else
            echo -e "${YELLOW}${BOLD}Voulez-vous changer pour la branche develop ?${NC}"
            select choice in "Oui" "Non"; do
                case $REPLY in
                    1)
                        git checkout develop || {
                            echo -e "${RED}${BOLD}Erreur:${NC} impossible de basculer sur develop."
                            exit 1
                        }
                        current_branch="develop"
                        BASE_BRANCH="develop"
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
    fi

    # Demander à l'utilisateur s'il veut continuer sur la branche actuelle ou en créer une nouvelle
    echo -e "${YELLOW}${BOLD}Que souhaitez-vous faire ?${NC}"
    echo -e "  ${GREEN}${BOLD}1) Continuer${NC} - Continuer à travailler sur la branche actuelle: ${BLUE}${current_branch}${NC}"
    echo -e "  ${YELLOW}${BOLD}2) Nouvelle branche${NC} - Créer une nouvelle branche basée sur ${BLUE}${MAIN_BRANCH}${NC}"

    # Ajouter l'option develop si elle existe et n'est pas la branche courante
    if check_develop_branch_exists && [[ "$current_branch" != "develop" ]]; then
        echo -e "  ${CYAN}${BOLD}3) Develop${NC} - Créer une nouvelle branche basée sur ${BLUE}develop${NC}"
        echo -e "  ${RED}${BOLD}4) Quitter${NC} - Abandonner le script"
        max_choice=4
    else
        echo -e "  ${RED}${BOLD}3) Quitter${NC} - Abandonner le script"
        max_choice=3
    fi

    while true; do
        read -p "Votre choix (1-$max_choice) : " choice
        case $choice in
            1)
                echo -e "${GREEN}${BOLD}Continuation sur la branche actuelle: ${BLUE}${current_branch}${NC}"
                BASE_BRANCH=$current_branch
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Création d'une nouvelle branche basée sur ${BLUE}${MAIN_BRANCH}${NC}"
                # On définit la branche de base comme la branche principale
                BASE_BRANCH=$MAIN_BRANCH
                break
                ;;
            3)
                if [[ $max_choice -eq 4 ]]; then
                    echo -e "${CYAN}${BOLD}Création d'une nouvelle branche basée sur ${BLUE}develop${NC}"
                    BASE_BRANCH="develop"
                    break
                else
                    echo -e "${RED}${BOLD}Abandon du script.${NC}"
                    exit 1
                fi
                ;;
            4)
                if [[ $max_choice -eq 4 ]]; then
                    echo -e "${RED}${BOLD}Abandon du script.${NC}"
                    exit 1
                else
                    echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner un nombre entre 1 et $max_choice.${NC}"
                fi
                ;;
            *)
                echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner un nombre entre 1 et $max_choice.${NC}"
                ;;
        esac
    done
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

    # Afficher chaque option avec ses couleurs et styles
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
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)

    # Si on est déjà sur la branche de base, on fait juste un pull
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        echo -e "${GREEN}${BOLD}Mise à jour de la branche ${BASE_BRANCH}...${NC}"
        git pull origin "$BASE_BRANCH" || exit 1
    else
        # Sinon, on bascule sur la branche de base
        echo -e "${GREEN}${BOLD}Création de la branche ${branch_name} à partir de ${BASE_BRANCH}...${NC}"
        git checkout "$BASE_BRANCH" || exit 1
        git pull origin "$BASE_BRANCH" || exit 1
    fi

    # Si on est sur la branche principale et qu'on veut créer une nouvelle branche
    if [[ "$current_branch" == "$BASE_BRANCH" && "$branch_name" != "$current_branch" ]]; then
        git checkout -b "$branch_name" || exit 1
    fi
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

# Fusionner dans la branche de base
merge_to_base() {
    local branch_name=$1
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)

    # Si on est déjà sur la branche de base, pas besoin de fusion
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        echo -e "${GREEN}${BOLD}Déjà sur la branche ${BASE_BRANCH}, pas besoin de fusion.${NC}"
        return 0
    fi

    # Si la branche actuelle est la même que celle qu'on veut fusionner, on pousse simplement
    if [[ "$current_branch" == "$branch_name" ]]; then
        echo -e "${YELLOW}${BOLD}Poussée de la branche ${branch_name}...${NC}"
        git push origin "$branch_name" || exit 1
        echo -e "${GREEN}${BOLD}Poussée réussie.${NC}"
        return 0
    fi

    # Sinon, on procède à la fusion
    echo -e "${YELLOW}${BOLD}Fusion de ${branch_name} dans ${BASE_BRANCH}...${NC}"
    git checkout "$BASE_BRANCH" || exit 1
    git pull origin "$BASE_BRANCH" || exit 1
    git merge --no-ff "$branch_name" || exit 1
    git push origin "$BASE_BRANCH" || exit 1
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

# Variable pour stocker le nom de la branche de travail
BRANCHE_TRAVAIL=""

# Si on continue sur la branche actuelle
if [[ "$BASE_BRANCH" != "$MAIN_BRANCH" ]]; then
    BRANCHE_TRAVAIL=$(git symbolic-ref --short HEAD)
    echo -e "${GREEN}${BOLD}Continuation du travail sur la branche : ${BLUE}${BRANCHE_TRAVAIL}${NC}"
else
    # Si on crée une nouvelle branche
    select_type_branche
    get_branch_name
    BRANCHE_TRAVAIL="${TYPE_BRANCHE}/${NOM_FONCTIONNALITE}"
    create_branch "$BRANCHE_TRAVAIL"
fi

# Valider et pousser les modifications
commit_and_push "$BRANCHE_TRAVAIL"

# Demander à l'utilisateur s'il souhaite fusionner dans la branche principale
echo -e "${YELLOW}${BOLD}Souhaitez-vous fusionner cette branche dans ${BLUE}${MAIN_BRANCH}${NC} ?"
select choice in "Oui" "Non"; do
    case $REPLY in
        1)
            merge_to_base "$BRANCHE_TRAVAIL"

            # Demander si l'utilisateur veut supprimer la branche après fusion
            if [[ "$BRANCHE_TRAVAIL" != "$MAIN_BRANCH" ]]; then
                echo -e "${YELLOW}${BOLD}Voulez-vous supprimer la branche ${BLUE}${BRANCHE_TRAVAIL}${NC} après la fusion ?${NC}"
                select _ in "Oui" "Non"; do
                    case $REPLY in
                        1)
                            delete_branch "$BRANCHE_TRAVAIL"
                            break
                            ;;
                        2)
                            echo -e "${GREEN}${BOLD}La branche ${BLUE}${BRANCHE_TRAVAIL}${NC} a été conservée.${NC}"
                            break
                            ;;
                        *)
                            echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1 ou 2.${NC}"
                            ;;
                    esac
                done
            fi
            break
            ;;
        2)
            echo -e "${GREEN}${BOLD}La branche ${BLUE}${BRANCHE_TRAVAIL}${NC} a été poussée mais pas fusionnée.${NC}"
            break
            ;;
        *)
            echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1 ou 2.${NC}"
            ;;
    esac
done

echo -e "${GREEN}${BOLD}Processus terminé avec succès. N'oubliez pas de créer une Pull Request sur GitHub si nécessaire.${NC}"
