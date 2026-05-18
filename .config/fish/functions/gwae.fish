function gwae -d "Git worktree add existing branch"
    set -l branch $argv[1]
    git worktree add "../"(basename (pwd))"-$branch" $branch
end
