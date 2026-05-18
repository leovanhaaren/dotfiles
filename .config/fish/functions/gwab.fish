function gwab -d "Git worktree add with new branch"
    set -l branch $argv[1]
    git worktree add -b $branch "../"(basename (pwd))"-$branch"
end
