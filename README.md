# Dotfiles

Personal dotfiles and development environment setup for Linux Mint.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/EnvSetup.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
bash install.sh
```

## What's Installed

### Development Tools
- **Java 21** (OpenJDK)
- **Maven** (latest)
- **Node.js** (via NVM)
- **pnpm**
- **Angular CLI**
- **Spring Boot CLI**

### Applications
- **VS Code**
- **IntelliJ IDEA Ultimate** (via JetBrains Toolbox)
- **Docker** + Docker Compose

### Shell
- **Starship** prompt
- **JetBrains Mono Nerd Font**

## File Structure

```
dotfiles/
├── .aliases           # Shell aliases
├── .bash_profile      # Bash profile
├── .bashrc            # Bash configuration
├── .exports           # Environment variables
├── .gitconfig         # Git configuration
├── .gitconfig_local.template  # Template for local git credentials
├── .gitignore_global  # Global gitignore
├── config/
│   └── starship.toml  # Starship prompt config
└── install.sh         # Installation script
```

## Post-Installation

### 1. Set Git Credentials

```bash
cp ~/.gitconfig_local.template ~/.gitconfig_local
# Edit ~/.gitconfig_local with your name and email
```

### 2. Configure Terminal Font

Set your terminal to use **JetBrains Mono Nerd Font** for proper Starship icons.

## Manual Customization

### Adding Local Git Config

Create `~/.gitconfig_local`:

```ini
[user]
    name = Your Name
    email = your.email@example.com
```

### Modifying Starship Prompt

Edit `~/.config/starship.toml`

## Version checks after install

echo "=== Version Check ===" && \
echo -n "java: " && (java --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "mvn: " && (mvn --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "node: " && (node --version 2>&1 || echo "NOT FOUND") && \
echo -n "npm: " && (npm --version 2>&1 || echo "NOT FOUND") && \
echo -n "pnpm: " && (pnpm --version 2>&1 || echo "NOT FOUND") && \
echo -n "ng: " && (ng version 2>&1 | grep "Angular CLI" || echo "NOT FOUND") && \
echo -n "spring: " && (spring --version 2>&1 || echo "NOT FOUND") && \
echo -n "docker: " && (docker --version 2>&1 || echo "NOT FOUND") && \
echo -n "code: " && (code --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "starship: " && (starship --version 2>&1 || echo "NOT FOUND") && \
echo -n "jetbrains-toolbox: " && (test -d ~/.local/share/JetBrains/Toolbox && echo "INSTALLED" || echo "NOT FOUND")