# Productivity
abbr -a w "cd ~/Workspaces"
abbr -a c "cd ~/Workspaces/claude"
abbr -a oc "cd ~/Workspaces/opencode"
alias reload "exec fish"
alias dotfiles "code $DOTFILES_DIR"
alias dotai "code ~/Workspaces/leovanhaaren/dot-ai"
alias claudedir "code ~/.claude"
alias ssh-load-keys "$HOME/Workspaces/leovanhaaren/dotfiles/scripts/ssh-load-keys.sh"

# Air (installed via go install)
alias air '(go env GOPATH)/bin/air'

# Symlinks
alias symlinkls "find . -maxdepth 1 -type l -ls"
alias symlinkrm "find . -maxdepth 1 -type l -delete"

# Git
alias greadme "git add README.md && git commit -m 'chore: Update README.md' && git push"

# Git Worktrees
abbr -a gwl "git worktree list"
abbr -a gwa "git worktree add"
abbr -a gwr "git worktree remove"
abbr -a gwp "git worktree prune"

# Tmux
abbr -a ta "tmux attach -t"
abbr -a tad "tmux attach -d -t"
abbr -a tl "tmux list-sessions"
abbr -a tn "tmux new-session -s"
abbr -a tna "tmux new-session -A -s"
abbr -a tk "tmux kill-session -t"
abbr -a tks "tmux kill-server"
abbr -a trw "tmux rename-window"

# Claude Code Container
alias bccc "docker build -t claude-code-sandbox ~/Workspaces/leovanhaaren/llm-container"
alias ccc "docker run -it -v (pwd):/app -v ~/.claude:/home/claude/.claude -v ~/.claude.json:/home/claude/.claude.json claude-code-sandbox"
