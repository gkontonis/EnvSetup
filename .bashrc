# Source aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Source exports (environment variables)
if [ -f ~/.exports ]; then
    . ~/.exports
fi

# SSH/GPG agent
if [ -f ~/.ssh_gpg_agent ]; then
    . ~/.ssh_gpg_agent
fi

export GPG_TTY=$(tty)

# ============================================================================
# BASH SHELL OPTIONS
# ============================================================================

# Typing a directory name just by itself will automatically change into that directory
shopt -s autocd

# Automatically fix directory name typos when changing directory
shopt -s cdspell

# Automatically expand directory globs and fix directory name typos whilst completing
shopt -s direxpand dirspell

# Enable the ** globstar recursive pattern in file and directory expansions
shopt -s globstar

# ============================================================================
# HISTORY SETTINGS
# ============================================================================

# Ignore lines which begin with a <space> and match previous entries
# Erase duplicate entries in history file
HISTCONTROL=ignoreboth:erasedups

# Ignore saving short- and other listed commands to the history file
HISTIGNORE=?:??:history

# The maximum number of lines in the history file
HISTFILESIZE=99999

# The number of entries to save in the history file
HISTSIZE=99999

# Set Bash to save each command to history, right after it has been executed
PROMPT_COMMAND='history -a'

# Save multi-line commands in one history entry
shopt -s cmdhist

# Append commands to the history file, instead of overwriting it
shopt -s histappend histverify

# ============================================================================
# NVM (Node Version Manager)
# ============================================================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ============================================================================
# PNPM
# ============================================================================
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ============================================================================
# STARSHIP PROMPT (must be at the end)
# ============================================================================
eval "$(starship init bash)"
