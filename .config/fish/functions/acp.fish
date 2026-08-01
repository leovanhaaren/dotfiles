function acp -d "Auto stage, generate AI commit message, and push"
    if not test -d .git
        set_color yellow; echo "=> Initializing git repository..."; set_color normal
        git init; or return 1
    end

    set_color blue; echo "=> Staging all files..."; set_color normal
    git add -A; or return 1

    set -l diff (git diff --cached --stat); or return 1
    if test -z "$diff"
        set_color yellow; echo "=> No changes to commit."; set_color normal
        return 0
    end

    set_color cyan; echo $diff; set_color normal
    echo
    set_color blue; echo "=> Generating commit message..."; set_color normal

    set -l msg (git diff --cached | pi -p --provider github-copilot --model claude-haiku-4.5 "Write a commit message in the Conventional Commits format. Use the structure:
    <type>(<optional scope>): <short description>

    <optional body>

    <optional footer>

Example types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Optionally, include a body for more details in bullet points.
Just return the commit message as plain text. Do not wrap it in backticks or any other formatting." | string replace -a '`' '')
    set -l generation_status $pipestatus
    for status_code in $generation_status
        if test $status_code -ne 0
            set_color red; echo "=> Commit message generation failed." >&2; set_color normal
            return 1
        end
    end
    if test -z (string trim -- "$msg")
        set_color red; echo "=> Commit message generation returned no text." >&2; set_color normal
        return 1
    end

    echo
    set_color --bold; echo "--- Proposed commit message ---"; set_color normal
    set_color green; echo $msg; set_color normal
    set_color --bold; echo "-------------------------------"; set_color normal
    echo

    if not git commit -m "$msg"
        set_color red; echo "=> Commit failed; nothing was pushed." >&2; set_color normal
        return 1
    end
    set_color blue; echo "=> Pushing to remote..."; set_color normal
    if not git push
        set_color red; echo "=> Push failed; the commit exists only locally." >&2; set_color normal
        return 1
    end
    set_color green; echo "=> Done."; set_color normal
end
