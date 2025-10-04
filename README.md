# 📦 GitPush - Git Workflow Automation Script
https://github.com/djoudj-dev/gitpush-auto/blob/main/version-fr.png
<div style="text-align: center;">
  <img src="https://img.shields.io/badge/Version-2.0.0-brightgreen" alt="Version 2.0.0">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue" alt="Platform: Linux | macOS | Windows">
  <img src="https://img.shields.io/badge/Language-Bash-green" alt="Language: Bash">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License: MIT">
</div>

*Read this in: [Français](#-gitpush---script-dautomatisation-du-flux-de-travail-git)*

GitPush is a powerful Bash script that automates your Git workflow, making branch management, commits, and merges faster and more organized. This script guides you through each step of the Git workflow with interactive prompts and colorful feedback.

## ✨ Features

### Core Features
- 🔍 Automatically detects main/master branch
- 🌿 Creates and manages feature branches with consistent naming
- 🔄 Handles branch switching, commits, and merges
- 🚀 Supports Git Flow workflow with develop branch
- 🎨 Beautiful colored terminal output
- 🌍 Works on Linux, macOS, and Windows (with Git Bash or WSL)

### Advanced Features
- 🧪 **Dry-run mode** - Preview actions without executing them
- 📝 **Logging system** - Automatic logging of all operations
- 🔀 **Pull Request creation** - Automatic PR creation via GitHub CLI
- 🗜️ **Commit squashing** - Interactive commit squash before merge
- 🏷️ **Version tagging** - Create and push version tags
- 🌐 **Network checks** - Verify connection before remote operations
- ⚠️ **Conflict management** - Enhanced merge conflict handling

## 🚀 Installation

### Linux

1. Download the script:
   ```bash
   curl -o git-push.sh https://raw.githubusercontent.com/yourusername/gitpush-auto/main/git-push.sh
   chmod +x git-push.sh
   ```

2. Create an alias in your shell configuration file:

   **For Bash (in ~/.bashrc):**
   ```bash
   echo 'alias gitpush="/path/to/git-push.sh"' >> ~/.bashrc
   source ~/.bashrc
   ```

   **For Zsh (in ~/.zshrc):**
   ```bash
   echo 'alias gitpush="/path/to/git-push.sh"' >> ~/.zshrc
   source ~/.zshrc
   ```

### macOS

1. Download the script:
   ```bash
   curl -o git-push.sh https://raw.githubusercontent.com/yourusername/gitpush-auto/main/git-push.sh
   chmod +x git-push.sh
   ```

2. Create an alias in your shell configuration file:

   **For Bash (in ~/.bash_profile):**
   ```bash
   echo 'alias gitpush="/path/to/git-push.sh"' >> ~/.bash_profile
   source ~/.bash_profile
   ```

   **For Zsh (in ~/.zshrc):**
   ```bash
   echo 'alias gitpush="/path/to/git-push.sh"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Windows

#### Option 1: Using Git Bash

1. Download the script and save it to a location on your computer
2. Open Git Bash and create an alias:
   ```bash
   echo 'alias gitpush="/path/to/git-push.sh"' >> ~/.bashrc
   source ~/.bashrc
   ```

#### Option 2: Using Windows Subsystem for Linux (WSL)

1. Install WSL if you haven't already
2. Follow the Linux installation instructions within your WSL environment

## 📋 Command-Line Options

GitPush supports several command-line options for advanced usage:

```bash
gitpush [OPTIONS]
```

### Available Options

| Option | Description |
|--------|-------------|
| `--help` | Display help message and usage information |
| `--version` | Display the current version of GitPush |
| `--dry-run` | Preview all actions without executing them |
| `--no-logs` | Disable logging for this session |

### Examples

```bash
# Normal execution
gitpush

# Preview actions without executing
gitpush --dry-run

# Run without logging
gitpush --no-logs

# Display version
gitpush --version

# Display help
gitpush --help
```

## 🎯 How to Use

Simply navigate to your Git repository and run:

```bash
gitpush
```

The script will guide you through the following steps:

### 1️⃣ Branch Selection

The script checks your current branch and offers options:
- Continue working on the current branch
- Create a new branch based on main/master
- Create a new branch based on develop (if it exists)

If you're on the main/master branch, the script will suggest creating or switching to the develop branch.

### 2️⃣ Branch Type Selection

When creating a new branch, you'll be prompted to select a branch type:
- ✨ feature - New features
- 🔄 refactor - Code refactoring
- 🛠️ fix - Bug fixes
- 🧰 chore - Routine tasks and maintenance
- 📦 update - Updates to dependencies or documentation
- 🚑 hotfix - Critical bug fixes
- 🚀 release - Release preparation

### 3️⃣ Branch Naming

Enter a descriptive name for your branch. The script will create a branch with the format `type/name` (e.g., `feature/user-authentication`).

### 4️⃣ Commit and Push

The script will:
- Add your changes (`git add .`)
- Prompt for a commit message
- Commit your changes
- Push the branch to the remote repository

### 5️⃣ Pull Request Creation

If you have [GitHub CLI](https://cli.github.com) installed, the script will offer to create a Pull Request:
- Enter a PR title (or use the branch name)
- Add an optional description
- The PR will be created automatically

### 6️⃣ Merge Options

After pushing your changes, you'll be asked if you want to:
- Merge your branch into the main branch
- Keep your branch without merging

### 7️⃣ Commit Squashing (Optional)

If you choose to merge and have multiple commits, you'll be offered the option to squash them:
- All commits will be combined into a single commit
- Enter a new commit message for the squashed commit
- This keeps your Git history clean

### 8️⃣ Version Tagging (Optional)

After a successful merge to the main branch, you can create a version tag:
- Enter a tag name (e.g., `v1.0.0`)
- Add an optional tag message
- The tag will be created and pushed automatically

### 9️⃣ Branch Cleanup

If you merged your branch, you'll have the option to delete it:
- Delete both local and remote branches
- Keep the branch for future work

## 📊 Logging System

GitPush automatically logs all operations to `~/.gitpush.log` for debugging and auditing purposes.

### Log Location
- **Linux/macOS**: `~/.gitpush.log`
- **Windows (Git Bash)**: `C:\Users\YourUsername\.gitpush.log`

### Viewing Logs
```bash
# View recent logs
tail -n 50 ~/.gitpush.log

# View logs in real-time
tail -f ~/.gitpush.log

# Search for errors
grep "ERROR" ~/.gitpush.log
```

### Disable Logging
```bash
gitpush --no-logs
```

## 🔧 Advanced Usage

### GitHub CLI Integration

For automatic Pull Request creation, install [GitHub CLI](https://cli.github.com):

**Linux/macOS:**
```bash
# Install GitHub CLI
brew install gh

# Or on Debian/Ubuntu
sudo apt install gh

# Authenticate
gh auth login
```

**Windows:**
```bash
# Using winget
winget install --id GitHub.cli
```

### Dry-Run Mode

Use dry-run mode to preview all actions before executing:

```bash
gitpush --dry-run
```

This will show you:
- All git commands that would be executed
- Branch operations that would be performed
- Files that would be modified
- No actual changes will be made

### Working with Develop Branch

The script supports Git Flow workflow:
1. If `develop` branch doesn't exist, the script will offer to create it
2. You can create feature branches based on `develop` instead of `main`
3. Merges can target either `develop` or `main` depending on your workflow

## 🔧 Troubleshooting

### Script Not Found
Make sure the path in your alias points to the correct location of the script and that the script has execute permissions (`chmod +x git-push.sh`).

### Color Issues
If you're not seeing colors in the output, make sure your terminal supports ANSI color codes.

### Git Not Found
Ensure Git is installed and accessible in your PATH.

### Permission Denied
If you get a "Permission denied" error, make sure the script has execute permissions:
```bash
chmod +x /path/to/git-push.sh
```

### Network Connection Issues
The script checks network connectivity before remote operations. If you encounter connection issues:
- Verify your internet connection
- Check your Git remote URL: `git remote -v`
- Ensure you have proper authentication (SSH keys or credentials)

### Merge Conflicts
If the script detects merge conflicts:
1. Choose "Resolve manually" when prompted
2. Open conflicting files and resolve conflicts
3. Run: `git add <resolved-files>`
4. Run: `git commit`
5. Re-run the script to continue

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

# 📦 GitPush - Script d'Automatisation du Flux de Travail Git

*Read this in: [English](#-gitpush---git-workflow-automation-script)*

GitPush est un puissant script Bash qui automatise votre flux de travail Git, rendant la gestion des branches, des commits et des fusions plus rapide et plus organisée. Ce script vous guide à travers chaque étape du flux de travail Git avec des invites interactives et des retours colorés.

## ✨ Fonctionnalités

### Fonctionnalités de Base
- 🔍 Détecte automatiquement la branche main/master
- 🌿 Crée et gère des branches de fonctionnalités avec une nomenclature cohérente
- 🔄 Gère les changements de branche, les commits et les fusions
- 🚀 Prend en charge le flux de travail Git Flow avec la branche develop
- 🎨 Belle sortie de terminal colorée
- 🌍 Fonctionne sur Linux, macOS et Windows (avec Git Bash ou WSL)

### Fonctionnalités Avancées
- 🧪 **Mode dry-run** - Prévisualise les actions sans les exécuter
- 📝 **Système de logging** - Journalisation automatique de toutes les opérations
- 🔀 **Création de Pull Request** - Création automatique de PR via GitHub CLI
- 🗜️ **Squash de commits** - Regroupement interactif des commits avant merge
- 🏷️ **Tags de version** - Création et envoi de tags de version
- 🌐 **Vérifications réseau** - Vérification de la connexion avant les opérations distantes
- ⚠️ **Gestion des conflits** - Gestion améliorée des conflits de fusion

## 🚀 Installation

### Linux

1. Téléchargez le script :
   ```bash
   curl -o git-push.sh https://raw.githubusercontent.com/yourusername/gitpush-auto/main/git-push.sh
   chmod +x git-push.sh
   ```

2. Créez un alias dans votre fichier de configuration shell :

   **Pour Bash (dans ~/.bashrc) :**
   ```bash
   echo 'alias gitpush="/chemin/vers/git-push.sh"' >> ~/.bashrc
   source ~/.bashrc
   ```

   **Pour Zsh (dans ~/.zshrc) :**
   ```bash
   echo 'alias gitpush="/chemin/vers/git-push.sh"' >> ~/.zshrc
   source ~/.zshrc
   ```

### macOS

1. Téléchargez le script :
   ```bash
   curl -o git-push.sh https://raw.githubusercontent.com/yourusername/gitpush-auto/main/git-push.sh
   chmod +x git-push.sh
   ```

2. Créez un alias dans votre fichier de configuration shell :

   **Pour Bash (dans ~/.bash_profile) :**
   ```bash
   echo 'alias gitpush="/chemin/vers/git-push.sh"' >> ~/.bash_profile
   source ~/.bash_profile
   ```

   **Pour Zsh (dans ~/.zshrc) :**
   ```bash
   echo 'alias gitpush="/chemin/vers/git-push.sh"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Windows

#### Option 1 : Utilisation de Git Bash

1. Téléchargez le script et enregistrez-le à un emplacement sur votre ordinateur
2. Ouvrez Git Bash et créez un alias :
   ```bash
   echo 'alias gitpush="/chemin/vers/git-push.sh"' >> ~/.bashrc
   source ~/.bashrc
   ```

#### Option 2 : Utilisation du Sous-système Windows pour Linux (WSL)

1. Installez WSL si ce n'est pas déjà fait
2. Suivez les instructions d'installation de Linux dans votre environnement WSL

## 📋 Options de Ligne de Commande

GitPush supporte plusieurs options de ligne de commande pour une utilisation avancée :

```bash
gitpush [OPTIONS]
```

### Options Disponibles

| Option | Description |
|--------|-------------|
| `--help` | Affiche le message d'aide et les informations d'utilisation |
| `--version` | Affiche la version actuelle de GitPush |
| `--dry-run` | Prévisualise toutes les actions sans les exécuter |
| `--no-logs` | Désactive la journalisation pour cette session |

### Exemples

```bash
# Exécution normale
gitpush

# Prévisualiser les actions sans les exécuter
gitpush --dry-run

# Exécuter sans journalisation
gitpush --no-logs

# Afficher la version
gitpush --version

# Afficher l'aide
gitpush --help
```

## 🎯 Comment Utiliser

Naviguez simplement vers votre dépôt Git et exécutez :

```bash
gitpush
```

Le script vous guidera à travers les étapes suivantes :

### 1️⃣ Sélection de Branche

Le script vérifie votre branche actuelle et propose des options :
- Continuer à travailler sur la branche actuelle
- Créer une nouvelle branche basée sur main/master
- Créer une nouvelle branche basée sur develop (si elle existe)

Si vous êtes sur la branche main/master, le script suggérera de créer ou de passer à la branche develop.

### 2️⃣ Sélection du Type de Branche

Lors de la création d'une nouvelle branche, vous serez invité à sélectionner un type de branche :
- ✨ feature - Nouvelles fonctionnalités
- 🔄 refactor - Refactorisation du code
- 🛠️ fix - Corrections de bugs
- 🧰 chore - Tâches routinières et maintenance
- 📦 update - Mises à jour des dépendances ou de la documentation
- 🚑 hotfix - Corrections critiques de bugs
- 🚀 release - Préparation de version

### 3️⃣ Nommage de Branche

Entrez un nom descriptif pour votre branche. Le script créera une branche avec le format `type/nom` (par exemple, `feature/authentification-utilisateur`).

### 4️⃣ Commit et Push

Le script va :
- Ajouter vos modifications (`git add .`)
- Demander un message de commit
- Valider vos modifications
- Pousser la branche vers le dépôt distant

### 5️⃣ Création de Pull Request

Si vous avez [GitHub CLI](https://cli.github.com) installé, le script proposera de créer une Pull Request :
- Entrez un titre pour la PR (ou utilisez le nom de la branche)
- Ajoutez une description optionnelle
- La PR sera créée automatiquement

### 6️⃣ Options de Fusion

Après avoir poussé vos modifications, on vous demandera si vous souhaitez :
- Fusionner votre branche dans la branche principale
- Garder votre branche sans fusion

### 7️⃣ Squash de Commits (Optionnel)

Si vous choisissez de fusionner et que vous avez plusieurs commits, vous aurez l'option de les regrouper :
- Tous les commits seront combinés en un seul commit
- Entrez un nouveau message de commit pour le commit regroupé
- Cela garde votre historique Git propre

### 8️⃣ Tags de Version (Optionnel)

Après une fusion réussie vers la branche principale, vous pouvez créer un tag de version :
- Entrez un nom de tag (ex: `v1.0.0`)
- Ajoutez un message de tag optionnel
- Le tag sera créé et poussé automatiquement

### 9️⃣ Nettoyage des Branches

Si vous avez fusionné votre branche, vous aurez l'option de la supprimer :
- Suppression des branches locales et distantes
- Conservation de la branche pour un travail futur

## 📊 Système de Journalisation

GitPush enregistre automatiquement toutes les opérations dans `~/.gitpush.log` à des fins de débogage et d'audit.

### Emplacement des Logs
- **Linux/macOS**: `~/.gitpush.log`
- **Windows (Git Bash)**: `C:\Users\VotreNom\.gitpush.log`

### Consultation des Logs
```bash
# Voir les logs récents
tail -n 50 ~/.gitpush.log

# Voir les logs en temps réel
tail -f ~/.gitpush.log

# Rechercher les erreurs
grep "ERROR" ~/.gitpush.log
```

### Désactiver la Journalisation
```bash
gitpush --no-logs
```

## 🔧 Utilisation Avancée

### Intégration GitHub CLI

Pour la création automatique de Pull Requests, installez [GitHub CLI](https://cli.github.com) :

**Linux/macOS:**
```bash
# Installer GitHub CLI
brew install gh

# Ou sur Debian/Ubuntu
sudo apt install gh

# S'authentifier
gh auth login
```

**Windows:**
```bash
# En utilisant winget
winget install --id GitHub.cli
```

### Mode Dry-Run

Utilisez le mode dry-run pour prévisualiser toutes les actions avant de les exécuter :

```bash
gitpush --dry-run
```

Cela vous montrera :
- Toutes les commandes git qui seraient exécutées
- Les opérations de branche qui seraient effectuées
- Les fichiers qui seraient modifiés
- Aucune modification réelle ne sera effectuée

### Travailler avec la Branche Develop

Le script supporte le workflow Git Flow :
1. Si la branche `develop` n'existe pas, le script proposera de la créer
2. Vous pouvez créer des branches de fonctionnalité basées sur `develop` au lieu de `main`
3. Les fusions peuvent cibler soit `develop` soit `main` selon votre workflow

## 🔧 Dépannage

### Script Non Trouvé
Assurez-vous que le chemin dans votre alias pointe vers l'emplacement correct du script et que le script a des permissions d'exécution (`chmod +x git-push.sh`).

### Problèmes de Couleur
Si vous ne voyez pas les couleurs dans la sortie, assurez-vous que votre terminal prend en charge les codes de couleur ANSI.

### Git Non Trouvé
Assurez-vous que Git est installé et accessible dans votre PATH.

### Permission Refusée
Si vous obtenez une erreur "Permission refusée", assurez-vous que le script a des permissions d'exécution :
```bash
chmod +x /chemin/vers/git-push.sh
```

### Problèmes de Connexion Réseau
Le script vérifie la connectivité réseau avant les opérations distantes. Si vous rencontrez des problèmes de connexion :
- Vérifiez votre connexion internet
- Vérifiez votre URL distante Git : `git remote -v`
- Assurez-vous d'avoir l'authentification appropriée (clés SSH ou identifiants)

### Conflits de Fusion
Si le script détecte des conflits de fusion :
1. Choisissez "Résoudre manuellement" lorsque demandé
2. Ouvrez les fichiers en conflit et résolvez les conflits
3. Exécutez : `git add <fichiers-résolus>`
4. Exécutez : `git commit`
5. Relancez le script pour continuer

## 📝 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.
