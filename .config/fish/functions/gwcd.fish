function gwcd -d "cd to a git worktree matching a pattern"
    set -l wt (git worktree list | grep -i $argv[1] | head -1 | awk '{print $1}')
    if test -n "$wt"
        cd $wt
    else
        echo "No worktree matching '$argv[1]'"
    end
end
