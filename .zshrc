export LC_ALL=en_US.UTF-8

# Initn starship
eval "$(starship init zsh)"

# Activate brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Accept auto-suugestion with esp (currently remapped with capslock)
bindkey '^[' autosuggest-accept

# Load completions
autoload -Uz compinit
compinit

# If you come from bash you might have to change your $PATH.
export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"

# Treat comments pasted into the command line as comments, not code.
setopt INTERACTIVE_COMMENTS

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Don't treat non-executable files in your $path as commands. This makes sure
# they don't show up as command completions. Settinig this option can impact
# performance on older systems, but should not be a problem on modern ones.
setopt HASH_EXECUTABLES_ONLY

# Enable ** and *** as shortcuts for **/* and ***/*, respectively.
# https://zsh.sourceforge.io/Doc/Release/Expansion.html#Recursive-Globbing
setopt GLOB_STAR_SHORT

# Alias
alias ls='ls --color=auto'
alias ll='ls -la'
alias key="cat ~/.ssh/id_rsa.pub | pbcopy"
alias gs="git status"
alias myip="curl icanhazip.com"
alias cg="cd $(git rev-parse --show-toplevel &> /dev/null)"
alias ggrep='git grep'
alias pasteonline="curl -F 'sprunge=<-' http://sprunge.us"
alias ss="ssh leseb@tarox"
alias gc="git commit -s"
alias gwip="git add -A && git commit -m wip"

function rr {
  branch=main
  if ! git ls-remote --exit-code --heads upstream main; then
    branch=master
  fi

  git fetch --all
  git pull upstream "$branch" --rebase
}

# Functions
# function gg - Pushes the current branch to the remote, and copies the commits to the clipboard so
# that they can be pasted into the PR description. TODO: use "gh" to create the PR? But that would
# overwrite the PR template, which is not ideal.
function gg {
  git_push=$(git push -f)

  # If the push failed, likely the pre-push hook failed
  if [[ $? -ne 0 ]]; then
    echo "$git_push"
    return 1
  fi

  echo "$git_push"

  # If the branch is up-to-date, exit
  if [[ "$git_push" == *"Everything up-to-date"* ]]; then
    return 0
  fi

  # Format the PR description - only if this is the first time pushing the branch
  branch=main
  if ! git ls-remote --exit-code --heads upstream main; then
    branch=master
  fi
  {
    git log --reverse --oneline upstream/"$branch"..HEAD
    echo
    git log --reverse upstream/"$branch"..HEAD
  } | pbcopy
  # Solution without 'gh' - https://stackoverflow.com/questions/60172766/
  #gh pr view --web
}

# Shell integrations
source <(fzf --zsh)
