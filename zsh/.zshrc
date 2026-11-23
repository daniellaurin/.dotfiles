# ==============================================================================
# 1. ENVIRONMENT & PATH
# ==============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export EDITOR="nvim"
export VISUAL="nvim"
PROMPT_EOL_MARK=""

# Keep PATH entries unique
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/.opencode/bin"
  "$HOME/.hermes/hermes-agent/bin"
  $path
)

# Load Hermes API keys if present
if [[ -f "$HOME/.hermes/.env" ]]; then
  set -a
  source "$HOME/.hermes/.env"
  set +a
  [[ -n "$GEMINI_API_KEY" ]] && export GOOGLE_GENERATIVE_AI_API_KEY="***"
fi

# ==============================================================================
# 2. HISTORY & COMPLETIONS (Plumbing — rarely needs editing)
# ==============================================================================
setopt INTERACTIVE_COMMENTS   # Allow # comments in interactive commands
setopt HIST_IGNORE_DUPS       # Don't record duplicate consecutive commands
setopt HIST_IGNORE_SPACE      # Commands starting with a space aren't saved
setopt SHARE_HISTORY          # Share history across open terminals
setopt EXTENDED_GLOB

HISTFILE="${XDG_STATE_HOME}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=10000
SAVEHIST=10000

# Enable LS_COLORS for ls, eza, and tab-completion menus
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

# Cache completion dump for 24h so shell startup stays fast
autoload -Uz compinit
ZCOMPDUMP="${XDG_CACHE_HOME}/zsh/zcompdump"
mkdir -p "$(dirname "$ZCOMPDUMP")"
if [[ -n ${ZCOMPDUMP}(#qN.mh+24) ]]; then
  compinit -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi
_comp_options+=(globdots)  # Include hidden dotfiles in tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ==============================================================================
# 3. VI MODE & KEYBINDS
# ==============================================================================
bindkey -v
export KEYTIMEOUT=1

# Up/Down & k/j search history matching what you already typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M vicmd '_'    vi-first-non-blank
bindkey -M vicmd 'k'    up-line-or-beginning-search
bindkey -M vicmd 'j'    down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search

bindkey '^[[1;5C' forward-word    # Ctrl+Right
bindkey '^[[1;5D' backward-word   # Ctrl+Left
bindkey '^[[3~'   delete-char     # Delete key

# ==============================================================================
# 4. PLUGINS & PROMPT (Works on both Arch & Debian/Ubuntu)
# ==============================================================================
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
for f in \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -r "$f" ]] && source "$f" && break
done

for f in \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r "$f" ]] && source "$f" && break
done

if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
  export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
  eval "$(starship init zsh)"
fi

# ==============================================================================
# 5. TOOL ACTIVATIONS
# ==============================================================================
command -v mise   >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v fzf    >/dev/null 2>&1 && source <(fzf --zsh)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ==============================================================================
# 6. ALIASES
# ==============================================================================
# Navigation & Basics
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias mkdir='mkdir -p'

# File Listing (eza if available, otherwise colored GNU ls)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -1   --icons=auto --color=auto'
  alias l='eza  -lh  --icons=auto'
  alias ll='eza -lh  --icons=auto --sort=name --group-directories-first'
  alias la='eza -lha --icons=auto --sort=name --group-directories-first'
  alias ld='eza -lhD --icons=auto'
  alias lt='eza --icons=auto --tree'
else
  alias ls='ls --color=auto'
  alias l='ls  -lh  --color=auto'
  alias ll='ls -lh  --color=auto --group-directories-first'
  alias la='ls -lha --color=auto --group-directories-first'
  alias ld='ls -lhD --color=auto'
fi

# Modern CLI Replacements
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --style=plain --paging=never --color auto'
  alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never --color always'
fi

if command -v duf >/dev/null 2>&1; then
  _df() { [[ $# -ge 1 && -e "${@: -1}" ]] && duf "${@: -1}" || duf; }
  alias df='_df'
fi

# ==============================================================================
# 7. FZF HELPER FUNCTIONS (ffcd, ffe, ffec)
# ==============================================================================
_pick_editor() {
  for e in "$EDITOR" "$VISUAL" nvim vim vi; do
    [[ -n "$e" ]] && command -v "$e" >/dev/null 2>&1 && { printf '%s' "$e"; return 0; }
  done
  return 1
}

# Fuzzy cd into a subdirectory
ffcd() {
  local dir
  dir=$(find . -maxdepth 7 \( -name .git -o -name node_modules -o -name .venv -o -name target -o -name .cache \) -prune -o -type d -print 2>/dev/null \
    | fzf --height 80% --layout=reverse --cycle --preview='ls -p --color=always {}' --preview-window=right:60% ${1:+--query="$1"})
  [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
}

# Fuzzy find a file and open in editor
ffe() {
  local file ed
  file=$(find . -maxdepth 5 -type f 2>/dev/null \
    | fzf --height 80% --layout=reverse --cycle --preview-window=right:60% ${1:+--query="$1"})
  [[ -n "$file" && -f "$file" ]] && ed=$(_pick_editor) && "$ed" "$file"
}

# Fuzzy grep file contents and open match in editor
ffec() {
  local file ed preview="cat {}"
  command -v bat >/dev/null 2>&1 && preview="bat --color always --style=plain --paging=never {}"
  file=$(grep -irl "${1:-}" ./ | fzf --height 80% --layout=reverse --cycle --preview="$preview" --preview-window=right:60%)
  [[ -n "$file" ]] && ed=$(_pick_editor) && "$ed" "$file"
}

# ==============================================================================
# 8. HOST-SPECIFIC OVERRIDES (e.g. Arch/HyDE aliases on tuf-arch)
# ==============================================================================
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
