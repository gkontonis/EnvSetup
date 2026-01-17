# Dotfiles – Reproducible Linux Mint Development Environment

![Terminal screenshot placeholder - starship prompt, JetBrains Mono font, custom bash prompt](screenshots/terminal-placeholder.png)

## Purpose

Setting up a consistent development environment across machines saves time and avoids configuration drift. This repository provides a reproducible setup for Linux Mint using versioned dotfiles and an automated install script. It allows developers to get started quickly, and ensures their favorite tools and configurations are always available.

## Motivation

I maintain this repo to speed up onboarding when starting new projects or moving to a new machine. With automated scripts, I can recreate my trusted environment in minutes, reducing setup frustration and errors.

## Technologies & Tools Included

| Feature              | Description                                                                 |
|----------------------|-----------------------------------------------------------------------------|
| Bash customization   | Includes aliases, environment variables, and custom bash profiles           |
| Java 21              | Installs OpenJDK 21 for Java development                                    |
| Maven                | Installs Maven build tool (latest release)                                  |
| Node.js/NVM          | Node.js installed via Node Version Manager for easy Node version switching  |
| pnpm                 | Fast, disk-efficient Node.js package manager                                |
| Angular CLI          | CLI for Angular development                                                 |
| Spring Boot CLI      | For rapid Spring Boot Java project setup                                    |
| VS Code              | Installs Visual Studio Code IDE                                             |
| IntelliJ IDEA Ultimate| Installs via JetBrains Toolbox                                             |
| Docker + Compose     | Enables container-based development                                         |
| Starship prompt      | Modern, customizable shell prompt                                           |
| JetBrains Mono Nerd Font | Ensures clean display of prompt icons in terminal                        |

## Screenshots

_Add screenshots or GIFs here to demonstrate the resulting terminal or environment setup._

- ![Placeholder - screenshot of customized terminal](screenshots/terminal-placeholder.png)
- ![Placeholder - installer running](screenshots/installer-placeholder.png)

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/EnvSetup.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
bash install.sh
```

## How to Use or Adapt

- **Clone and run the install script**: The repository is designed for Linux Mint, but can be adapted for other Debian/Ubuntu-based distributions with minor changes.
- **Customize configs**: Edit files like `.bashrc`, `.aliases`, `.exports`, or add configs for your personal tools.
- **Add or remove tools**: Modify `install.sh` to add/remove software installations or steps.
- **Contribute**: Suggestions or improvements are welcome! Open an issue or pull request.

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

### Set Git Credentials

```bash
cp ~/.gitconfig_local.template ~/.gitconfig_local
# Edit ~/.gitconfig_local with your name and email
```

### Configure Terminal Font

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

Run this snippet to verify tool installation:
```bash
echo "=== Version Check ===" && \
echo -n "java: " && (java --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "mvn: " && (mvn --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "node: " && (node --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "npm: " && (npm --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "pnpm: " && (pnpm --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "ng: " && (ng version 2>&1 | grep "Angular CLI" || echo "NOT FOUND") && \
echo -n "spring: " && (spring --version 2>&1 || echo "NOT FOUND") && \
echo -n "docker: " && (docker --version 2>&1 || echo "NOT FOUND") && \
echo -n "code: " && (code --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "starship: " && (starship --version 2>&1 || echo "NOT FOUND") && \
echo -n "jetbrains-toolbox: " && (test -d ~/.local/share/JetBrains/Toolbox && echo "INSTALLED" || echo "NOT FOUND")
```

## Customization & Extensibility

- **Easily extensible:** Add/remove config files and install steps to suit your needs.
- **Portable:** Designed for Linux Mint, adaptable for Ubuntu/Debian systems.
- **Personalization:** Customize dotfiles and install script for your workflow.

---

_For suggestions, improvements, or collaboration, feel free to open an Issue or a Pull Request._
