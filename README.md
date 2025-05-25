# 📦 GitPush - Git Workflow Automation Script

<div style="text-align: center;">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue" alt="Platform: Linux | macOS | Windows">
  <img src="https://img.shields.io/badge/Language-Bash-green" alt="Language: Bash">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License: MIT">
</div>

*Read this in: [Français](#-gitpush---script-dautomatisation-du-flux-de-travail-git)*

GitPush is a powerful Bash script that automates your Git workflow, making branch management, commits, and merges faster and more organized. This script guides you through each step of the Git workflow with interactive prompts and colorful feedback.

## ✨ Features

- 🔍 Automatically detects main/master branch
- 🌿 Creates and manages feature branches with consistent naming
- 🔄 Handles branch switching, commits, and merges
- 🚀 Supports Git Flow workflow with develop branch
- 🎨 Beautiful colored terminal output
- 🌍 Works on Linux, macOS, and Windows (with Git Bash or WSL)

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

### 5️⃣ Merge Options

After pushing your changes, you'll be asked if you want to:
- Merge your branch into the main branch
- Keep your branch without merging

If you choose to merge, you'll also have the option to delete the branch after merging.

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

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

# 📦 GitPush - Script d'Automatisation du Flux de Travail Git

*Read this in: [English](#-gitpush---git-workflow-automation-script)*

GitPush est un puissant script Bash qui automatise votre flux de travail Git, rendant la gestion des branches, des commits et des fusions plus rapide et plus organisée. Ce script vous guide à travers chaque étape du flux de travail Git avec des invites interactives et des retours colorés.

## ✨ Fonctionnalités

- 🔍 Détecte automatiquement la branche main/master
- 🌿 Crée et gère des branches de fonctionnalités avec une nomenclature cohérente
- 🔄 Gère les changements de branche, les commits et les fusions
- 🚀 Prend en charge le flux de travail Git Flow avec la branche develop
- 🎨 Belle sortie de terminal colorée
- 🌍 Fonctionne sur Linux, macOS et Windows (avec Git Bash ou WSL)

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

### 5️⃣ Options de Fusion

Après avoir poussé vos modifications, on vous demandera si vous souhaitez :
- Fusionner votre branche dans la branche principale
- Garder votre branche sans fusion

Si vous choisissez de fusionner, vous aurez également la possibilité de supprimer la branche après la fusion.

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

## 📝 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.
