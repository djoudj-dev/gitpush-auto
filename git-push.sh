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

# Variables globales
DRY_RUN=false
ENABLE_LOGS=true
LOG_FILE="${HOME}/.gitpush.log"
CONFIG_FILE="${HOME}/.gitpush.conf"
VERSION="2.0.0"

# Fonction de logging
log_message() {
    local level=$1
    local message=$2
    if [[ "$ENABLE_LOGS" == true ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    fi
}

# Fonction pour afficher l'aide
show_help() {
    echo -e "${BOLD}GitPush v${VERSION}${NC}"
    echo -e "${YELLOW}Usage:${NC} $(basename "$0") [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}--dry-run${NC}        Prévisualiser les actions sans les exécuter"
    echo -e "  ${GREEN}--no-logs${NC}        Désactiver l'enregistrement des logs"
    echo -e "  ${GREEN}--version${NC}        Afficher la version du script"
    echo -e "  ${GREEN}--help${NC}           Afficher ce message d'aide"
    echo ""
    echo -e "${YELLOW}Exemples:${NC}"
    echo -e "  $(basename "$0")              # Exécution normale"
    echo -e "  $(basename "$0") --dry-run    # Mode prévisualisation"
    exit 0
}

# Traiter les arguments de ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            echo -e "${CYAN}${BOLD}Mode DRY-RUN activé - Aucune modification ne sera effectuée${NC}"
            log_message "INFO" "Mode dry-run activé"
            shift
            ;;
        --no-logs)
            ENABLE_LOGS=false
            shift
            ;;
        --version)
            echo -e "${BOLD}GitPush v${VERSION}${NC}"
            exit 0
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${RED}${BOLD}Option inconnue: $1${NC}"
            show_help
            ;;
    esac
done

# Vérifier la connexion réseau
check_network() {
    if ! git ls-remote --exit-code origin &>/dev/null; then
        echo -e "${RED}${BOLD}Erreur:${NC} Impossible de se connecter au dépôt distant."
        echo -e "${YELLOW}${BOLD}Vérifiez votre connexion réseau et réessayez.${NC}"
        log_message "ERROR" "Échec de la connexion au dépôt distant"
        exit 1
    fi
    log_message "INFO" "Connexion au dépôt distant réussie"
}

# Exécuter une commande (respecte le mode dry-run)
execute_command() {
    local cmd=$1
    local description=${2:-"Exécution de la commande"}

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}${BOLD}[DRY-RUN]${NC} $description: ${YELLOW}$cmd${NC}"
        log_message "DRY-RUN" "$description: $cmd"
    else
        log_message "EXEC" "$description: $cmd"
        eval "$cmd"
        return $?
    fi
    return 0
}

# Vérifier si GitHub CLI est installé
check_gh_cli() {
    if command -v gh &> /dev/null; then
        return 0
    fi
    return 1
}

# Créer une Pull Request avec GitHub CLI
create_pull_request() {
    local branch_name=$1
    local base_branch=${2:-$MAIN_BRANCH}

    if ! check_gh_cli; then
        echo -e "${YELLOW}${BOLD}GitHub CLI (gh) n'est pas installé.${NC}"
        echo -e "${CYAN}Installez-le pour créer automatiquement des Pull Requests: ${BLUE}https://cli.github.com${NC}"
        log_message "WARN" "GitHub CLI non disponible pour la création de PR"
        return 1
    fi

    echo -e "${YELLOW}${BOLD}Voulez-vous créer une Pull Request ?${NC}"
    select choice in "Oui" "Non"; do
        case $REPLY in
            1)
                read -e -p "Titre de la PR (vide pour utiliser le nom de branche): " pr_title
                read -e -p "Description de la PR (optionnel): " pr_description

                if [[ -z "$pr_title" ]]; then
                    pr_title="${branch_name}"
                fi

                local gh_cmd="gh pr create --base \"$base_branch\" --head \"$branch_name\" --title \"$pr_title\""
                if [[ -n "$pr_description" ]]; then
                    gh_cmd="$gh_cmd --body \"$pr_description\""
                fi

                execute_command "$gh_cmd" "Création de la Pull Request"

                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}${BOLD}Pull Request créée avec succès !${NC}"
                    log_message "INFO" "Pull Request créée: $pr_title"
                else
                    echo -e "${RED}${BOLD}Erreur lors de la création de la Pull Request.${NC}"
                    log_message "ERROR" "Échec de la création de la Pull Request"
                fi
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Pull Request non créée.${NC}"
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1 ou 2.${NC}"
                ;;
        esac
    done
}

# Squash commits interactif
squash_commits() {
    local branch_name=$1
    local base_branch=$2

    echo -e "${YELLOW}${BOLD}Voulez-vous squash vos commits avant le merge ?${NC}"
    select choice in "Oui" "Non"; do
        case $REPLY in
            1)
                local commit_count=$(git rev-list --count "$base_branch".."$branch_name")
                if [[ $commit_count -le 1 ]]; then
                    echo -e "${YELLOW}${BOLD}Un seul commit détecté, pas besoin de squash.${NC}"
                    return 0
                fi

                echo -e "${CYAN}${BOLD}$commit_count commits seront squashés.${NC}"
                execute_command "git reset --soft $base_branch" "Reset soft vers $base_branch"

                if [[ "$DRY_RUN" == false ]]; then
                    read -e -p "Message du commit squashé: " squash_message
                    execute_command "git commit -m \"$squash_message\"" "Création du commit squashé"
                fi

                log_message "INFO" "Commits squashés: $commit_count commits → 1 commit"
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Pas de squash.${NC}"
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1 ou 2.${NC}"
                ;;
        esac
    done
}

# Créer un tag de version
create_version_tag() {
    echo -e "${YELLOW}${BOLD}Voulez-vous créer un tag de version ?${NC}"
    select choice in "Oui" "Non"; do
        case $REPLY in
            1)
                read -e -p "Nom du tag (ex: v1.0.0): " tag_name
                read -e -p "Message du tag (optionnel): " tag_message

                if [[ -z "$tag_name" ]]; then
                    echo -e "${RED}${BOLD}Le nom du tag ne peut pas être vide.${NC}"
                    return 1
                fi

                local tag_cmd="git tag"
                if [[ -n "$tag_message" ]]; then
                    tag_cmd="$tag_cmd -a \"$tag_name\" -m \"$tag_message\""
                else
                    tag_cmd="$tag_cmd \"$tag_name\""
                fi

                execute_command "$tag_cmd" "Création du tag $tag_name"
                execute_command "git push origin \"$tag_name\"" "Push du tag vers le dépôt distant"

                echo -e "${GREEN}${BOLD}Tag $tag_name créé et poussé avec succès.${NC}"
                log_message "INFO" "Tag créé: $tag_name"
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Aucun tag créé.${NC}"
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Choix invalide. Veuillez sélectionner 1 ou 2.${NC}"
                ;;
        esac
    done
}

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
    log_message "INFO" "Création de la branche develop depuis $main_branch"

    execute_command "git checkout \"$main_branch\"" "Basculer vers $main_branch" || exit 1
    execute_command "git pull origin \"$main_branch\"" "Mettre à jour $main_branch" || exit 1
    execute_command "git checkout -b develop" "Créer la branche develop" || exit 1
    execute_command "git push -u origin develop" "Pousser develop vers le dépôt distant" || exit 1

    echo -e "${GREEN}${BOLD}Branche develop créée avec succès.${NC}"
    log_message "INFO" "Branche develop créée avec succès"
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

    log_message "INFO" "Création de branche: $branch_name depuis $BASE_BRANCH"

    # Si on est déjà sur la branche de base, on fait juste un pull
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        echo -e "${GREEN}${BOLD}Mise à jour de la branche ${BASE_BRANCH}...${NC}"
        execute_command "git pull origin \"$BASE_BRANCH\"" "Mettre à jour $BASE_BRANCH" || exit 1
    else
        # Sinon, on bascule sur la branche de base
        echo -e "${GREEN}${BOLD}Création de la branche ${branch_name} à partir de ${BASE_BRANCH}...${NC}"
        execute_command "git checkout \"$BASE_BRANCH\"" "Basculer vers $BASE_BRANCH" || exit 1
        execute_command "git pull origin \"$BASE_BRANCH\"" "Mettre à jour $BASE_BRANCH" || exit 1
    fi

    # Si on est sur la branche principale et qu'on veut créer une nouvelle branche
    if [[ "$current_branch" == "$BASE_BRANCH" && "$branch_name" != "$current_branch" ]]; then
        execute_command "git checkout -b \"$branch_name\"" "Créer la branche $branch_name" || exit 1
        log_message "INFO" "Branche $branch_name créée avec succès"
    fi
}

# Valider et pousser les modifications
commit_and_push() {
    local branch_name=$1

    log_message "INFO" "Début du commit et push pour $branch_name"

    if ! git diff --quiet || ! git diff --cached --quiet; then
        read -e -p "Entrez le message de commit : " MESSAGE_COMMIT

        execute_command "git add ." "Ajout des modifications" || exit 1
        execute_command "git commit -m \"$MESSAGE_COMMIT\"" "Création du commit" || exit 1

        log_message "INFO" "Commit créé: $MESSAGE_COMMIT"
    fi

    # Vérifier la connexion réseau avant de pousser
    check_network

    execute_command "git push -u origin \"$branch_name\"" "Push vers le dépôt distant" || exit 1

    echo -e "${GREEN}${BOLD}La branche ${branch_name} a été poussée avec succès.${NC}"
    log_message "INFO" "Branche $branch_name poussée avec succès"
}

# Fusionner dans la branche de base
merge_to_base() {
    local branch_name=$1
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)

    log_message "INFO" "Début de la fusion de $branch_name vers $BASE_BRANCH"

    # Si on est déjà sur la branche de base, pas besoin de fusion
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        echo -e "${GREEN}${BOLD}Déjà sur la branche ${BASE_BRANCH}, pas besoin de fusion.${NC}"
        log_message "INFO" "Déjà sur $BASE_BRANCH, aucune fusion nécessaire"
        return 0
    fi

    # Si la branche actuelle est la même que celle qu'on veut fusionner, on pousse simplement
    if [[ "$current_branch" == "$branch_name" ]]; then
        echo -e "${YELLOW}${BOLD}Poussée de la branche ${branch_name}...${NC}"
        execute_command "git push origin \"$branch_name\"" "Push de $branch_name" || exit 1
        echo -e "${GREEN}${BOLD}Poussée réussie.${NC}"
        log_message "INFO" "Branche $branch_name poussée avec succès"
        return 0
    fi

    # Proposer le squash avant merge
    squash_commits "$branch_name" "$BASE_BRANCH"

    # Sinon, on procède à la fusion
    echo -e "${YELLOW}${BOLD}Fusion de ${branch_name} dans ${BASE_BRANCH}...${NC}"

    execute_command "git checkout \"$BASE_BRANCH\"" "Basculer vers $BASE_BRANCH" || exit 1
    execute_command "git pull origin \"$BASE_BRANCH\"" "Mettre à jour $BASE_BRANCH" || exit 1

    # Tentative de merge avec gestion des conflits
    if [[ "$DRY_RUN" == false ]]; then
        if ! git merge --no-ff "$branch_name"; then
            echo -e "${RED}${BOLD}Conflit de fusion détecté !${NC}"
            echo -e "${YELLOW}${BOLD}Options disponibles :${NC}"
            echo -e "  ${GREEN}1) Résoudre manuellement${NC} - Ouvrez vos fichiers et résolvez les conflits"
            echo -e "  ${RED}2) Annuler le merge${NC} - Annuler la fusion et revenir à l'état précédent"

            select choice in "Résoudre" "Annuler"; do
                case $REPLY in
                    1)
                        echo -e "${YELLOW}${BOLD}Résolvez les conflits dans vos fichiers, puis :${NC}"
                        echo -e "  1. ${CYAN}git add <fichiers-résolus>${NC}"
                        echo -e "  2. ${CYAN}git commit${NC}"
                        echo -e "  3. Relancez ce script pour continuer"
                        log_message "WARN" "Conflits de merge détectés sur $branch_name → $BASE_BRANCH"
                        exit 1
                        ;;
                    2)
                        git merge --abort
                        echo -e "${RED}${BOLD}Fusion annulée.${NC}"
                        log_message "INFO" "Fusion annulée par l'utilisateur"
                        exit 1
                        ;;
                    *)
                        echo -e "${RED}${BOLD}Choix invalide.${NC}"
                        ;;
                esac
            done
        fi
    else
        execute_command "git merge --no-ff \"$branch_name\"" "Merge de $branch_name vers $BASE_BRANCH"
    fi

    execute_command "git push origin \"$BASE_BRANCH\"" "Push de $BASE_BRANCH vers le dépôt distant" || exit 1

    echo -e "${GREEN}${BOLD}Fusion réussie.${NC}"
    log_message "INFO" "Fusion réussie: $branch_name → $BASE_BRANCH"
}

# Supprimer une branche locale et distante après fusion
delete_branch() {
    local branch_name=$1

    log_message "INFO" "Suppression de la branche: $branch_name"

    echo -e "${YELLOW}${BOLD}Suppression de la branche locale ${branch_name}...${NC}"

    if [[ "$DRY_RUN" == false ]]; then
        if ! git branch -d "$branch_name"; then
            echo -e "${YELLOW}${BOLD}Aucune modification détectée dans ${branch_name}. Suppression forcée.${NC}"
            git branch -D "$branch_name"
        fi
    else
        execute_command "git branch -d \"$branch_name\"" "Suppression de la branche locale $branch_name"
    fi

    echo -e "${GREEN}${BOLD}Branche locale supprimée avec succès.${NC}"

    # Suppression de la branche distante
    echo -e "${YELLOW}${BOLD}Suppression de la branche distante ${branch_name}...${NC}"

    if [[ "$DRY_RUN" == false ]]; then
        if ! git push origin --delete "$branch_name"; then
            echo -e "${RED}${BOLD}Erreur : impossible de supprimer la branche distante ${branch_name}.${NC}"
            log_message "ERROR" "Échec de la suppression de la branche distante $branch_name"
        else
            echo -e "${GREEN}${BOLD}Branche distante ${branch_name} supprimée avec succès.${NC}"
            log_message "INFO" "Branche $branch_name supprimée (locale et distante)"
        fi
    else
        execute_command "git push origin --delete \"$branch_name\"" "Suppression de la branche distante $branch_name"
    fi
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

# Proposer de créer une Pull Request
if [[ "$BRANCHE_TRAVAIL" != "$MAIN_BRANCH" && "$BRANCHE_TRAVAIL" != "develop" ]]; then
    create_pull_request "$BRANCHE_TRAVAIL" "$BASE_BRANCH"
fi

# Demander à l'utilisateur s'il souhaite fusionner dans la branche principale
echo -e "${YELLOW}${BOLD}Souhaitez-vous fusionner cette branche dans ${BLUE}${MAIN_BRANCH}${NC} ?"
select choice in "Oui" "Non"; do
    case $REPLY in
        1)
            merge_to_base "$BRANCHE_TRAVAIL"

            # Proposer de créer un tag de version après une fusion réussie
            if [[ "$BASE_BRANCH" == "$MAIN_BRANCH" ]]; then
                create_version_tag
            fi

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

echo -e "${GREEN}${BOLD}Processus terminé avec succès !${NC}"
log_message "INFO" "Script terminé avec succès"
