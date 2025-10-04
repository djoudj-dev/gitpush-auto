#!/bin/bash

# Define ANSI color codes and styles
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;39m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'
ORANGE='\033[38;5;214m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Global variables
DRY_RUN=false
ENABLE_LOGS=true
LOG_FILE="${HOME}/.gitpush.log"
CONFIG_FILE="${HOME}/.gitpush.conf"
VERSION="2.0.0"

# Logging function
log_message() {
    local level=$1
    local message=$2
    if [[ "$ENABLE_LOGS" == true ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    fi
}

# Function to display help
show_help() {
    echo -e "${BOLD}GitPush v${VERSION}${NC}"
    echo -e "${YELLOW}Usage:${NC} $(basename "$0") [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}--dry-run${NC}        Preview actions without executing them"
    echo -e "  ${GREEN}--no-logs${NC}        Disable logging"
    echo -e "  ${GREEN}--version${NC}        Display the script version"
    echo -e "  ${GREEN}--help${NC}           Display this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  $(basename "$0")              # Normal execution"
    echo -e "  $(basename "$0") --dry-run    # Preview mode"
    exit 0
}

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            echo -e "${CYAN}${BOLD}DRY-RUN mode activated - No changes will be made${NC}"
            log_message "INFO" "Dry-run mode enabled"
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
            echo -e "${RED}${BOLD}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# Check network connection
check_network() {
    if ! git ls-remote --exit-code origin &>/dev/null; then
        echo -e "${RED}${BOLD}Error:${NC} Unable to connect to remote repository."
        echo -e "${YELLOW}${BOLD}Check your network connection and try again.${NC}"
        log_message "ERROR" "Failed to connect to remote repository"
        exit 1
    fi
    log_message "INFO" "Successfully connected to remote repository"
}

# Execute a command (respects dry-run mode)
execute_command() {
    local cmd=$1
    local description=${2:-"Executing command"}

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

# Check if GitHub CLI is installed
check_gh_cli() {
    if command -v gh &> /dev/null; then
        return 0
    fi
    return 1
}

# Create a Pull Request with GitHub CLI
create_pull_request() {
    local branch_name=$1
    local base_branch=${2:-$MAIN_BRANCH}

    if ! check_gh_cli; then
        echo -e "${YELLOW}${BOLD}GitHub CLI (gh) is not installed.${NC}"
        echo -e "${CYAN}Install it to automatically create Pull Requests: ${BLUE}https://cli.github.com${NC}"
        log_message "WARN" "GitHub CLI not available for PR creation"
        return 1
    fi

    echo -e "${YELLOW}${BOLD}Do you want to create a Pull Request?${NC}"
    select choice in "Yes" "No"; do
        case $REPLY in
            1)
                read -e -p "PR title (empty to use branch name): " pr_title
                read -e -p "PR description (optional): " pr_description

                if [[ -z "$pr_title" ]]; then
                    pr_title="${branch_name}"
                fi

                local gh_cmd="gh pr create --base \"$base_branch\" --head \"$branch_name\" --title \"$pr_title\""
                if [[ -n "$pr_description" ]]; then
                    gh_cmd="$gh_cmd --body \"$pr_description\""
                fi

                execute_command "$gh_cmd" "Creating Pull Request"

                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}${BOLD}Pull Request created successfully!${NC}"
                    log_message "INFO" "Pull Request created: $pr_title"
                else
                    echo -e "${RED}${BOLD}Error creating Pull Request.${NC}"
                    log_message "ERROR" "Failed to create Pull Request"
                fi
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Pull Request not created.${NC}"
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
                ;;
        esac
    done
}

# Interactive commit squashing
squash_commits() {
    local branch_name=$1
    local base_branch=$2

    echo -e "${YELLOW}${BOLD}Do you want to squash your commits before merging?${NC}"
    select choice in "Yes" "No"; do
        case $REPLY in
            1)
                local commit_count=$(git rev-list --count "$base_branch".."$branch_name")
                if [[ $commit_count -le 1 ]]; then
                    echo -e "${YELLOW}${BOLD}Only one commit detected, no need to squash.${NC}"
                    return 0
                fi

                echo -e "${CYAN}${BOLD}$commit_count commits will be squashed.${NC}"
                execute_command "git reset --soft $base_branch" "Soft reset to $base_branch"

                if [[ "$DRY_RUN" == false ]]; then
                    read -e -p "Squashed commit message: " squash_message
                    execute_command "git commit -m \"$squash_message\"" "Creating squashed commit"
                fi

                log_message "INFO" "Commits squashed: $commit_count commits → 1 commit"
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}No squashing.${NC}"
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
                ;;
        esac
    done
}

# Create a version tag
create_version_tag() {
    echo -e "${YELLOW}${BOLD}Do you want to create a version tag?${NC}"
    select choice in "Yes" "No"; do
        case $REPLY in
            1)
                read -e -p "Tag name (e.g., v1.0.0): " tag_name
                read -e -p "Tag message (optional): " tag_message

                if [[ -z "$tag_name" ]]; then
                    echo -e "${RED}${BOLD}Tag name cannot be empty.${NC}"
                    return 1
                fi

                local tag_cmd="git tag"
                if [[ -n "$tag_message" ]]; then
                    tag_cmd="$tag_cmd -a \"$tag_name\" -m \"$tag_message\""
                else
                    tag_cmd="$tag_cmd \"$tag_name\""
                fi

                execute_command "$tag_cmd" "Creating tag $tag_name"
                execute_command "git push origin \"$tag_name\"" "Pushing tag to remote repository"

                echo -e "${GREEN}${BOLD}Tag $tag_name created and pushed successfully.${NC}"
                log_message "INFO" "Tag created: $tag_name"
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}No tag created.${NC}"
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
                ;;
        esac
    done
}

# Detect the main branch (master or main)
detect_main_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        echo "main" # Default to main if neither exists
    fi
}

# Check if develop branch exists
check_develop_branch_exists() {
    git show-ref --verify --quiet refs/heads/develop
    return $?
}

# Create develop branch from main branch
create_develop_branch() {
    local main_branch=$1
    echo -e "${YELLOW}${BOLD}Creating develop branch from ${BLUE}${main_branch}${NC}..."
    log_message "INFO" "Creating develop branch from $main_branch"

    execute_command "git checkout \"$main_branch\"" "Switch to $main_branch" || exit 1
    execute_command "git pull origin \"$main_branch\"" "Update $main_branch" || exit 1
    execute_command "git checkout -b develop" "Create develop branch" || exit 1
    execute_command "git push -u origin develop" "Push develop to remote repository" || exit 1

    echo -e "${GREEN}${BOLD}Develop branch created successfully.${NC}"
    log_message "INFO" "Develop branch created successfully"
}

# Detected main branch
MAIN_BRANCH=$(detect_main_branch)
# Base branch for new features (defaults to main branch)
BASE_BRANCH=$MAIN_BRANCH

# List of accepted branch types with icons
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

# Function to validate branch name
validate_branch_name() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}${BOLD}Error:${NC} Feature name cannot be empty."
        return 1
    fi
    if [[ ! $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo -e "${RED}${BOLD}Error:${NC} Feature name must start with a letter or number and contain only letters, numbers, hyphens (-), and underscores (_)."
        return 1
    fi
    if [[ ${#name} -gt 50 ]]; then
        echo -e "${RED}${BOLD}Error:${NC} Name is too long (maximum 50 characters)."
        return 1
    fi
    return 0
}

# Check active branch
check_branch() {
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)
    echo -e "${YELLOW}${BOLD}You are currently on branch: ${BLUE}${current_branch}${NC}"

    # Check if on main branch (master or main)
    if [[ "$current_branch" == "$MAIN_BRANCH" ]]; then
        echo -e "${RED}${BOLD}Error:${NC} You cannot work directly on the main branch ($MAIN_BRANCH)."

        # Check if develop branch exists
        if ! check_develop_branch_exists; then
            echo -e "${YELLOW}${BOLD}The develop branch does not exist. Do you want to create it?${NC}"
            select choice in "Yes" "No"; do
                case $REPLY in
                    1)
                        create_develop_branch "$MAIN_BRANCH"
                        current_branch="develop"
                        BASE_BRANCH="develop"
                        break
                        ;;
                    2)
                        echo -e "${RED}${BOLD}Aborting script.${NC}"
                        exit 1
                        ;;
                    *)
                        echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
                        ;;
                esac
            done
        else
            echo -e "${YELLOW}${BOLD}Do you want to switch to the develop branch?${NC}"
            select choice in "Yes" "No"; do
                case $REPLY in
                    1)
                        git checkout develop || {
                            echo -e "${RED}${BOLD}Error:${NC} Unable to switch to develop."
                            exit 1
                        }
                        current_branch="develop"
                        BASE_BRANCH="develop"
                        break
                        ;;
                    2)
                        echo -e "${RED}${BOLD}Aborting script.${NC}"
                        exit 1
                        ;;
                    *)
                        echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
                        ;;
                esac
            done
        fi
    fi

    # Ask user if they want to continue on current branch or create a new one
    echo -e "${YELLOW}${BOLD}What would you like to do?${NC}"
    echo -e "  ${GREEN}${BOLD}1) Continue${NC} - Continue working on current branch: ${BLUE}${current_branch}${NC}"
    echo -e "  ${YELLOW}${BOLD}2) New branch${NC} - Create a new branch based on ${BLUE}${MAIN_BRANCH}${NC}"

    # Add develop option if it exists and is not the current branch
    if check_develop_branch_exists && [[ "$current_branch" != "develop" ]]; then
        echo -e "  ${CYAN}${BOLD}3) Develop${NC} - Create a new branch based on ${BLUE}develop${NC}"
        echo -e "  ${RED}${BOLD}4) Quit${NC} - Abort the script"
        max_choice=4
    else
        echo -e "  ${RED}${BOLD}3) Quit${NC} - Abort the script"
        max_choice=3
    fi

    while true; do
        read -p "Your choice (1-$max_choice): " choice
        case $choice in
            1)
                echo -e "${GREEN}${BOLD}Continuing on current branch: ${BLUE}${current_branch}${NC}"
                BASE_BRANCH=$current_branch
                break
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Creating a new branch based on ${BLUE}${MAIN_BRANCH}${NC}"
                # Set base branch as main branch
                BASE_BRANCH=$MAIN_BRANCH
                break
                ;;
            3)
                if [[ $max_choice -eq 4 ]]; then
                    echo -e "${CYAN}${BOLD}Creating a new branch based on ${BLUE}develop${NC}"
                    BASE_BRANCH="develop"
                    break
                else
                    echo -e "${RED}${BOLD}Aborting script.${NC}"
                    exit 1
                fi
                ;;
            4)
                if [[ $max_choice -eq 4 ]]; then
                    echo -e "${RED}${BOLD}Aborting script.${NC}"
                    exit 1
                else
                    echo -e "${RED}${BOLD}Invalid choice. Please select a number between 1 and $max_choice.${NC}"
                fi
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid choice. Please select a number between 1 and $max_choice.${NC}"
                ;;
        esac
    done
}

# Check for unstaged local changes
check_local_changes() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo -e "${RED}${BOLD}Error:${NC} You have uncommitted local changes."
        echo -e "${YELLOW}${BOLD}Do you want to commit or stash them?${NC}"
        echo -e "  ${GREEN}${BOLD}1) Commit${NC} - Add and commit your changes."
        echo -e "  ${YELLOW}${BOLD}2) Stash${NC} - Temporarily save your changes to return to later."
        echo -e "  ${RED}${BOLD}3) Cancel${NC} - Abort the script without doing anything."

        # Read user choice
        read -p "Your choice (1, 2, or 3): " choice
        case $choice in
            1)
                echo -e "${YELLOW}${BOLD}Committing local changes...${NC}"
                git add . || exit 1
                read -e -p "Enter commit message: " MESSAGE_COMMIT
                git commit -m "$MESSAGE_COMMIT" || exit 1
                ;;
            2)
                echo -e "${YELLOW}${BOLD}Stashing local changes...${NC}"
                git stash || exit 1
                ;;
            3)
                echo -e "${RED}${BOLD}Aborting script.${NC}"
                exit 1
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid choice. Please select 1, 2, or 3.${NC}"
                check_local_changes # Restart function on invalid choice
                ;;
        esac
    fi
}

# Select branch type
select_type_branche() {
    echo -e "${YELLOW}${BOLD}Select branch type:${NC}"

    # Display each option with colors and styles
    for i in "${!BRANCH_ICONS[@]}"; do
        echo -e "  ${BOLD}$((i+1))) ${BRANCH_ICONS[i]}${NC}"
    done

    # Read user choice
    while true; do
        read -p "Your choice (1-${#BRANCH_ICONS[@]}): " choice
        if [[ "$choice" =~ ^[1-7]$ ]] && (( choice >= 1 && choice <= ${#BRANCH_ICONS[@]} )); then
            TYPE_BRANCHE=${BRANCH_TYPES[$((choice-1))]}
            echo -e "${GREEN}${BOLD}Selected type: ${BRANCH_ICONS[$((choice-1))]}${NC}"
            break
        else
            echo -e "${RED}${BOLD}Invalid choice. Please enter a number between 1 and ${#BRANCH_ICONS[@]}.${NC}"
        fi
    done
}

# Request and validate feature name
get_branch_name() {
    while true; do
        read -e -p "Enter feature name: " NOM_FONCTIONNALITE
        if validate_branch_name "$NOM_FONCTIONNALITE"; then
            break
        fi
        echo -e "${YELLOW}${BOLD}Please try again.${NC}"
    done
}

# Create a feature branch
create_branch() {
    local branch_name=$1
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)

    log_message "INFO" "Creating branch: $branch_name from $BASE_BRANCH"

    # If already on base branch, just pull
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        echo -e "${GREEN}${BOLD}Updating branch ${BASE_BRANCH}...${NC}"
        execute_command "git pull origin \"$BASE_BRANCH\"" "Update $BASE_BRANCH" || exit 1
    else
        # Otherwise, switch to base branch
        echo -e "${GREEN}${BOLD}Creating branch ${branch_name} from ${BASE_BRANCH}...${NC}"
        execute_command "git checkout \"$BASE_BRANCH\"" "Switch to $BASE_BRANCH" || exit 1
        execute_command "git pull origin \"$BASE_BRANCH\"" "Update $BASE_BRANCH" || exit 1
    fi

    # If on main branch and want to create a new branch
    if [[ "$current_branch" == "$BASE_BRANCH" && "$branch_name" != "$current_branch" ]]; then
        execute_command "git checkout -b \"$branch_name\"" "Create branch $branch_name" || exit 1
        log_message "INFO" "Branch $branch_name created successfully"
    fi
}

# Commit and push changes
commit_and_push() {
    local branch_name=$1

    log_message "INFO" "Starting commit and push for $branch_name"

    if ! git diff --quiet || ! git diff --cached --quiet; then
        read -e -p "Enter commit message: " MESSAGE_COMMIT

        execute_command "git add ." "Adding changes" || exit 1
        execute_command "git commit -m \"$MESSAGE_COMMIT\"" "Creating commit" || exit 1

        log_message "INFO" "Commit created: $MESSAGE_COMMIT"
    fi

    # Check network connection before pushing
    check_network

    execute_command "git push -u origin \"$branch_name\"" "Push to remote repository" || exit 1

    echo -e "${GREEN}${BOLD}Branch ${branch_name} has been pushed successfully.${NC}"
    log_message "INFO" "Branch $branch_name pushed successfully"
}

# Merge into base branch
merge_to_base() {
    local branch_name=$1
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD)

    log_message "INFO" "Starting merge of $branch_name to $BASE_BRANCH"

    # If already on base branch, no need to merge
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        echo -e "${GREEN}${BOLD}Already on branch ${BASE_BRANCH}, no need to merge.${NC}"
        log_message "INFO" "Already on $BASE_BRANCH, no merge needed"
        return 0
    fi

    # If current branch is the one to merge, just push
    if [[ "$current_branch" == "$branch_name" ]]; then
        echo -e "${YELLOW}${BOLD}Pushing branch ${branch_name}...${NC}"
        execute_command "git push origin \"$branch_name\"" "Push $branch_name" || exit 1
        echo -e "${GREEN}${BOLD}Push successful.${NC}"
        log_message "INFO" "Branch $branch_name pushed successfully"
        return 0
    fi

    # Offer squash before merge
    squash_commits "$branch_name" "$BASE_BRANCH"

    # Otherwise, proceed with merge
    echo -e "${YELLOW}${BOLD}Merging ${branch_name} into ${BASE_BRANCH}...${NC}"

    execute_command "git checkout \"$BASE_BRANCH\"" "Switch to $BASE_BRANCH" || exit 1
    execute_command "git pull origin \"$BASE_BRANCH\"" "Update $BASE_BRANCH" || exit 1

    # Attempt merge with conflict handling
    if [[ "$DRY_RUN" == false ]]; then
        if ! git merge --no-ff "$branch_name"; then
            echo -e "${RED}${BOLD}Merge conflict detected!${NC}"
            echo -e "${YELLOW}${BOLD}Available options:${NC}"
            echo -e "  ${GREEN}1) Resolve manually${NC} - Open your files and resolve conflicts"
            echo -e "  ${RED}2) Abort merge${NC} - Cancel the merge and return to previous state"

            select choice in "Resolve" "Abort"; do
                case $REPLY in
                    1)
                        echo -e "${YELLOW}${BOLD}Resolve conflicts in your files, then:${NC}"
                        echo -e "  1. ${CYAN}git add <resolved-files>${NC}"
                        echo -e "  2. ${CYAN}git commit${NC}"
                        echo -e "  3. Re-run this script to continue"
                        log_message "WARN" "Merge conflicts detected on $branch_name → $BASE_BRANCH"
                        exit 1
                        ;;
                    2)
                        git merge --abort
                        echo -e "${RED}${BOLD}Merge aborted.${NC}"
                        log_message "INFO" "Merge aborted by user"
                        exit 1
                        ;;
                    *)
                        echo -e "${RED}${BOLD}Invalid choice.${NC}"
                        ;;
                esac
            done
        fi
    else
        execute_command "git merge --no-ff \"$branch_name\"" "Merge $branch_name to $BASE_BRANCH"
    fi

    execute_command "git push origin \"$BASE_BRANCH\"" "Push $BASE_BRANCH to remote repository" || exit 1

    echo -e "${GREEN}${BOLD}Merge successful.${NC}"
    log_message "INFO" "Merge successful: $branch_name → $BASE_BRANCH"
}

# Delete local and remote branch after merge
delete_branch() {
    local branch_name=$1

    log_message "INFO" "Deleting branch: $branch_name"

    echo -e "${YELLOW}${BOLD}Deleting local branch ${branch_name}...${NC}"

    if [[ "$DRY_RUN" == false ]]; then
        if ! git branch -d "$branch_name"; then
            echo -e "${YELLOW}${BOLD}No changes detected in ${branch_name}. Force deleting.${NC}"
            git branch -D "$branch_name"
        fi
    else
        execute_command "git branch -d \"$branch_name\"" "Delete local branch $branch_name"
    fi

    echo -e "${GREEN}${BOLD}Local branch deleted successfully.${NC}"

    # Delete remote branch
    echo -e "${YELLOW}${BOLD}Deleting remote branch ${branch_name}...${NC}"

    if [[ "$DRY_RUN" == false ]]; then
        if ! git push origin --delete "$branch_name"; then
            echo -e "${RED}${BOLD}Error: Unable to delete remote branch ${branch_name}.${NC}"
            log_message "ERROR" "Failed to delete remote branch $branch_name"
        else
            echo -e "${GREEN}${BOLD}Remote branch ${branch_name} deleted successfully.${NC}"
            log_message "INFO" "Branch $branch_name deleted (local and remote)"
        fi
    else
        execute_command "git push origin --delete \"$branch_name\"" "Delete remote branch $branch_name"
    fi
}

# Main script
check_branch
check_local_changes

# Variable to store working branch name
BRANCHE_TRAVAIL=""

# If continuing on current branch
if [[ "$BASE_BRANCH" != "$MAIN_BRANCH" ]]; then
    BRANCHE_TRAVAIL=$(git symbolic-ref --short HEAD)
    echo -e "${GREEN}${BOLD}Continuing work on branch: ${BLUE}${BRANCHE_TRAVAIL}${NC}"
else
    # If creating a new branch
    select_type_branche
    get_branch_name
    BRANCHE_TRAVAIL="${TYPE_BRANCHE}/${NOM_FONCTIONNALITE}"
    create_branch "$BRANCHE_TRAVAIL"
fi

# Commit and push changes
commit_and_push "$BRANCHE_TRAVAIL"

# Offer to create a Pull Request
if [[ "$BRANCHE_TRAVAIL" != "$MAIN_BRANCH" && "$BRANCHE_TRAVAIL" != "develop" ]]; then
    create_pull_request "$BRANCHE_TRAVAIL" "$BASE_BRANCH"
fi

# Ask user if they want to merge into main branch
echo -e "${YELLOW}${BOLD}Do you want to merge this branch into ${BLUE}${MAIN_BRANCH}${NC}?"
select choice in "Yes" "No"; do
    case $REPLY in
        1)
            merge_to_base "$BRANCHE_TRAVAIL"

            # Offer to create a version tag after successful merge
            if [[ "$BASE_BRANCH" == "$MAIN_BRANCH" ]]; then
                create_version_tag
            fi

            # Ask if user wants to delete branch after merge
            if [[ "$BRANCHE_TRAVAIL" != "$MAIN_BRANCH" ]]; then
                echo -e "${YELLOW}${BOLD}Do you want to delete branch ${BLUE}${BRANCHE_TRAVAIL}${NC} after the merge?${NC}"
                select _ in "Yes" "No"; do
                    case $REPLY in
                        1)
                            delete_branch "$BRANCHE_TRAVAIL"
                            break
                            ;;
                        2)
                            echo -e "${GREEN}${BOLD}Branch ${BLUE}${BRANCHE_TRAVAIL}${NC} has been kept.${NC}"
                            break
                            ;;
                        *)
                            echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
                            ;;
                    esac
                done
            fi
            break
            ;;
        2)
            echo -e "${GREEN}${BOLD}Branch ${BLUE}${BRANCHE_TRAVAIL}${NC} has been pushed but not merged.${NC}"
            break
            ;;
        *)
            echo -e "${RED}${BOLD}Invalid choice. Please select 1 or 2.${NC}"
            ;;
    esac
done

echo -e "${GREEN}${BOLD}Process completed successfully!${NC}"
log_message "INFO" "Script completed successfully"
