#!/bin/bash

# ============================================================================
# SETUP
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_DIR="$HOME/dotfiles"
LOGFILE="$HOME/install.log"

# Log everything
exec > >(tee -a "$LOGFILE") 2>&1

echo "============================================"
echo "Install started: $(date)"
echo "DOTFILES_DIR: $DOTFILES_DIR"
echo "============================================"

# ============================================================================
# INITIAL SYSTEM UPDATE & NALA INSTALLATION
# ============================================================================
log_info "Performing initial system update..."
sudo apt update -y && sudo apt upgrade -y

log_info "Installing git and nala..."
sudo apt install -y git nala

# From now on, use nala instead of apt
log_info "Switching to nala for package management..."

# ============================================================================
# LINK DOTFILES FIRST (so .exports is available)
# ============================================================================
log_info "Linking dotfiles..."

link_file() {
    local src="$1"
    local dest="$2"
    
    if [ ! -f "$src" ]; then
        log_error "Source file missing: $src"
        return 1
    fi
    
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.backup.$(date +%Y%m%d%H%M%S)"
        log_warn "Backed up: $dest"
    fi
    
    rm -f "$dest"
    ln -s "$src" "$dest"
    
    if [ -L "$dest" ]; then
        log_info "Linked: $dest -> $src"
    else
        log_error "Failed to link: $dest"
    fi
}

link_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
link_file "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
link_file "$DOTFILES_DIR/.exports" "$HOME/.exports"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

if [ ! -f "$HOME/.gitconfig_local" ]; then
    cp "$DOTFILES_DIR/.gitconfig_local.template" "$HOME/.gitconfig_local"
    log_warn "Created ~/.gitconfig_local - EDIT WITH YOUR NAME/EMAIL"
fi

# Source exports now
[ -f "$HOME/.exports" ] && source "$HOME/.exports"

# ============================================================================
# SYSTEM UPDATE (using nala)
# ============================================================================
log_info "Updating system packages with nala..."
sudo nala update
sudo nala upgrade --assume-yes

# ============================================================================
# ESSENTIAL PACKAGES
# ============================================================================
log_info "Installing essential packages..."
sudo nala install --assume-yes \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    unzip \
    zip \
    jq \
    tree \
    htop \
    net-tools \
    fontconfig

# ============================================================================
# STARSHIP PROMPT
# ============================================================================
log_info "Installing Starship..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    log_info "Starship installed"
else
    log_warn "Starship already installed"
fi

# ============================================================================
# NERD FONTS
# ============================================================================
log_info "Installing Nerd Fonts..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    cd /tmp
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip -O JetBrainsMono.zip
    if [ -f "JetBrainsMono.zip" ]; then
        unzip -o JetBrainsMono.zip -d "$FONT_DIR"
        rm -f JetBrainsMono.zip
        fc-cache -fv
        log_info "Nerd Fonts installed"
    else
        log_error "Failed to download Nerd Fonts"
    fi
else
    log_warn "Nerd Fonts already installed"
fi

# ============================================================================
# DOCKER
# ============================================================================
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo nala remove --assume-yes docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo nala update
    sudo nala install --assume-yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    sudo usermod -aG docker "$USER"
    log_info "Docker installed (log out/in for group changes)"
else
    log_warn "Docker already installed"
fi

# ============================================================================
# JAVA
# ============================================================================
log_info "Installing Java 21..."
if ! dpkg -l | grep -q openjdk-21-jdk; then
    sudo nala install --assume-yes openjdk-21-jdk
    log_info "Java 21 installed"
else
    log_warn "Java 21 already installed"
fi

# ============================================================================
# MAVEN - FIXED WITH ROBUST VERSION DETECTION
# ============================================================================
log_info "Installing Maven..."

# Check if Maven is actually functional, not just if directory exists
MAVEN_WORKS=false
if [ -f "/opt/maven/bin/mvn" ]; then
    if /opt/maven/bin/mvn --version &>/dev/null; then
        MAVEN_WORKS=true
    fi
fi

if [ "$MAVEN_WORKS" = false ]; then
    cd /tmp
    rm -f maven.tar.gz 2>/dev/null
    sudo rm -rf /opt/maven /opt/apache-maven-* 2>/dev/null  # Clean previous failed installs
    
    # Use archive.apache.org which is more reliable for specific versions
    MAVEN_VERSION="3.9.9"
    MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
    
    log_info "Downloading Maven ${MAVEN_VERSION} from archive.apache.org..."
    wget -q "$MAVEN_URL" -O maven.tar.gz
    
    if [ -f "maven.tar.gz" ] && [ -s "maven.tar.gz" ]; then
        # Verify it's actually a gzip file
        if file maven.tar.gz | grep -q "gzip compressed"; then
            sudo tar -xzf maven.tar.gz -C /opt
            
            if [ -d "/opt/apache-maven-${MAVEN_VERSION}" ]; then
                sudo ln -sfn /opt/apache-maven-${MAVEN_VERSION} /opt/maven
                rm -f maven.tar.gz
                
                # Verify installation actually works
                if [ -f "/opt/maven/bin/mvn" ] && /opt/maven/bin/mvn --version &>/dev/null; then
                    log_info "Maven ${MAVEN_VERSION} installed and verified successfully"
                else
                    log_error "Maven binary exists but failed to execute"
                fi
            else
                log_error "Maven directory not found after extraction"
            fi
        else
            log_error "Downloaded file is not a valid gzip archive"
            rm -f maven.tar.gz
        fi
    else
        log_error "Failed to download Maven ${MAVEN_VERSION}"
    fi
else
    log_warn "Maven already installed and working"
fi

# Add Maven to PATH for this session
export PATH="/opt/maven/bin:$PATH"

# ============================================================================
# NVM + NODE
# ============================================================================
log_info "Installing NVM and Node.js..."
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    log_info "NVM installed"
fi

# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm &> /dev/null; then
    if ! command -v node &> /dev/null; then
        nvm install --lts
        nvm alias default node
        log_info "Node.js LTS installed"
    else
        log_warn "Node.js already installed: $(node --version)"
    fi
else
    log_error "NVM failed to load"
fi

# ============================================================================
# PNPM
# ============================================================================
log_info "Installing pnpm..."
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

if [ ! -d "$PNPM_HOME" ]; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    log_info "pnpm installed"
else
    log_warn "pnpm already installed"
fi

# ============================================================================
# ANGULAR CLI
# ============================================================================
log_info "Installing Angular CLI..."
if command -v npm &> /dev/null; then
    if ! npm list -g @angular/cli &> /dev/null; then
        npm install -g @angular/cli
        log_info "Angular CLI installed"
    else
        log_warn "Angular CLI already installed"
    fi
else
    log_error "npm not available - skipping Angular CLI"
fi

# ============================================================================
# SPRING BOOT CLI
# ============================================================================
log_info "Installing Spring Boot CLI..."
if [ ! -d "/opt/spring-3.4.1" ]; then
    cd /tmp
    wget https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-cli/3.4.1/spring-boot-cli-3.4.1-bin.tar.gz -O spring.tar.gz
    if [ -f "spring.tar.gz" ]; then
        sudo tar -xzf spring.tar.gz -C /opt
        sudo ln -sf /opt/spring-3.4.1 /opt/spring
        rm -f spring.tar.gz
        log_info "Spring Boot CLI installed to /opt/spring"
    else
        log_error "Failed to download Spring Boot CLI"
    fi
else
    log_warn "Spring Boot CLI already installed"
fi

export PATH="/opt/spring/bin:$PATH"

# ============================================================================
# VS CODE
# ============================================================================
log_info "Installing VS Code..."
if ! command -v code &> /dev/null; then
    cd /tmp
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    
    sudo nala update
    sudo nala install --assume-yes code
    
    if command -v code &> /dev/null; then
        log_info "VS Code installed"
    else
        log_error "VS Code installation failed"
    fi
else
    log_warn "VS Code already installed"
fi

# ============================================================================
# JETBRAINS TOOLBOX - SIMPLIFIED APPROACH
# ============================================================================
log_info "Installing JetBrains Toolbox..."
TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"

if [ ! -d "$TOOLBOX_DIR" ] || [ ! -f "$TOOLBOX_DIR/bin/jetbrains-toolbox" ]; then
    cd /tmp
    rm -rf jetbrains-toolbox* 2>/dev/null  # Clean any previous attempts
    
    log_info "Downloading JetBrains Toolbox..."
    
    # Use the simplified working approach
    if curl -fSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | jq -r '.TBA[0].downloads.linux.link' | xargs curl -fSL -o jetbrains-toolbox.tar.gz; then
        
        if [ -s "jetbrains-toolbox.tar.gz" ]; then
            log_info "Extracting JetBrains Toolbox..."
            tar -xzf jetbrains-toolbox.tar.gz
            
            # Run the toolbox - it will install itself to ~/.local/share/JetBrains/Toolbox/
            log_info "Launching JetBrains Toolbox (it will self-install)..."
            ./jetbrains-toolbox-*/bin/jetbrains-toolbox &
            
            # Wait for it to start and self-install
            sleep 5
            
            if pgrep -f "jetbrains-toolbox" > /dev/null; then
                log_info "JetBrains Toolbox launched - it will self-install to ~/.local/share/JetBrains/Toolbox/"
                log_info "Use the GUI to install IntelliJ IDEA"
            else
                log_warn "JetBrains Toolbox may not have started - run manually: ~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"
            fi
            
            # Cleanup downloaded files
            rm -rf jetbrains-toolbox*
        else
            log_error "Downloaded file is empty or corrupted"
            rm -f jetbrains-toolbox.tar.gz
        fi
    else
        log_error "Failed to download JetBrains Toolbox"
    fi
else
    log_warn "JetBrains Toolbox already installed"
fi

# ============================================================================
# VERIFICATION
# ============================================================================
echo ""
echo "============================================"
log_info "VERIFICATION"
echo "============================================"

# Reload all paths
export PATH="/opt/maven/bin:/opt/spring/bin:$PNPM_HOME:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

FAILED=""
for cmd in java mvn node npm pnpm ng spring docker code starship; do
    echo -n "$cmd: "
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        FAILED="$FAILED $cmd"
    fi
done

echo ""
echo "Symlinks:"
for f in .bashrc .bash_profile .aliases .exports .gitconfig; do
    if [ -L "$HOME/$f" ]; then
        echo -e "$f: ${GREEN}✓${NC}"
    else
        echo -e "$f: ${RED}✗${NC}"
    fi
done

echo ""
echo "============================================"
log_info "Install finished: $(date)"
echo "Log saved to: $LOGFILE"
echo "============================================"

if [ -n "$FAILED" ]; then
    log_error "Failed tools:$FAILED"
    log_error "Check $LOGFILE for details"
fi

echo ""
log_warn "NEXT STEPS:"
echo "  1. Run: source ~/.bashrc"
echo "  2. Log out and back in (Docker group)"
echo "  3. Edit ~/.gitconfig_local with your name/email"
echo "  4. Set terminal font to JetBrains Mono Nerd Font"
echo "  5. Open JetBrains Toolbox and install IntelliJ"

echo ""
echo "============================================"
log_info "VERSION CHECK COMMAND"
echo "============================================"
echo 'Run this command to verify all installations:'
echo ''
cat << 'EOF'
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
echo -n "starship: " && (starship --version 2>&1 | head -1 || echo "NOT FOUND") && \
echo -n "jetbrains-toolbox: " && (test -d ~/.local/share/JetBrains/Toolbox && echo "INSTALLED" || echo "NOT FOUND")
EOF