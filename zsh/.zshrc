# --- XDG & PATH ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/.opencode/bin"
  "$HOME/.hermes/hermes-agent/bin"
  $path
)
export EDITOR="nvim"
export VISUAL="nvim"

# --- History & Shell Options ---
setopt INTERACTIVE_COMMENTS HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
HISTFILE="${XDG_STATE_HOME}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=10000
SAVEHIST=10000

# --- Fast Completions ---
autoload -Uz compinit
setopt EXTENDED_GLOB
ZCOMPDUMP="${XDG_CACHE_HOME}/zsh/zcompdump"
mkdir -p "$(dirname "$ZCOMPDUMP")"
if [[ -n ${ZCOMPDUMP}(#qN.mh+24) ]]; then
  compinit -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi
_comp_options+=(globdots)

# --- Vi Mode & History Prefix Search ---
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -v
export KEYTIMEOUT=1
bindkey -M vicmd '_' vi-first-non-blank
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char

# --- Lightweight Plugins (Arch & Debian/Ubuntu system paths) ---
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

# --- Prompt (Starship) ---
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
  export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
  eval "$(starship init zsh)"
fi

# --- Tool Activations (Coder / Devbox / Local) ---
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
if [[ -f "$HOME/.hermes/.env" ]]; then
  set -a && source "$HOME/.hermes/.env" && set +a
  [[ -n "$GEMINI_API_KEY" ]] && export GOOGLE_GENERATIVE_AI_API_KEY="$GEMINI_API_KEY"
fi

# --- Guarded Modern Aliases ---
alias c='clear' ..='cd ..' ...='cd ../..' .3='cd ../../..' .4='cd ../../../..' mkdir='mkdir -p'

if command -v eza >/dev/null 2>&1; then
  alias l='eza -lh --icons=auto' \
        ll='eza -lha --icons=auto --sort=name --group-directories-first' \
        ld='eza -lhD --icons=auto' \
        lt='eza --icons=auto --tree'
fi
if command -v bat >/dev/null 2>&1; then
  alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never --color always'
  alias cat='bat --style=plain --paging=never --color auto'
fi
if command -v duf >/dev/null 2>&1; then
  _df() { [[ $# -ge 1 && -e "${@: -1}" ]] && duf "${@: -1}" || duf; }
  alias df='_df'
fi

# --- FZF Helpers (from HyDE) ---
_pick_editor() {
  for e in "$EDITOR" "$VISUAL" nvim vim vi; do
    [[ -n "$e" ]] && command -v "$e" >/dev/null 2>&1 && { printf '%s' "$e"; return 0; }
  done
  return 1
}

ffcd() {
  local dir
  dir=$(find . -maxdepth 7 \( -name .git -o -name node_modules -o -name .venv -o -name target -o -name .cache \) -prune -o -type d -print 2>/dev/null \
    | fzf --height 80% --layout=reverse --cycle --preview='ls -p {}' --preview-window=right:60% ${1:+--query="$1"})
  [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
}

ffe() {
  local file ed
  file=$(find . -maxdepth 5 -type f 2>/dev/null \
    | fzf --height 80% --layout=reverse --cycle --preview-window=right:60% ${1:+--query="$1"})
  [[ -n "$file" && -f "$file" ]] && ed=$(_pick_editor) && "$ed" "$file"
}

ffec() {
  local file ed preview="cat {}"
  command -v bat >/dev/null 2>&1 && preview="bat --color always --style=plain --paging=never {}"
  file=$(grep -irl "${1:-}" ./ | fzf --height 80% --layout=reverse --cycle --preview="$preview" --preview-window=right:60%)
  [[ -n "$file" ]] && ed=$(_pick_editor) && "$ed" "$file"
}

# --- Host-Specific Overrides (e.g., HyDE on tuf-arch) ---
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
