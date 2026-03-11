function commit -d "Stage and generate AI commit message from diff"
    if not test -d .git
        set_color yellow; echo "=> Initializing git repository..."; set_color normal
        git init
    end

    set -l diff (git diff --cached --stat)
    if test -z "$diff"
        set_color yellow; echo "=> No changes to commit."; set_color normal
        return 0
    end

    set_color cyan; echo $diff; set_color normal
    echo
    set_color blue; echo "=> Generating commit message..."; set_color normal

    set -l msg (git diff --cached | claude -p --model haiku "Write a commit message in the Conventional Commits format. Use the structure:
    <type>(<optional scope>): <short description>

    <optional body>

    <optional footer>

Example types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Optionally, include a body for more details in bullet points.
Just return the commit message as plain text. Do not wrap it in backticks or any other formatting." | string replace -a '`' '')

    echo
    set_color --bold; echo "--- Proposed commit message ---"; set_color normal
    set_color green; echo $msg; set_color normal
    set_color --bold; echo "-------------------------------"; set_color normal
    echo

    read -P "Commit with this message? [y/N] " confirm
    if string match -qi y $confirm
        git commit -m "$msg"
        set_color green; echo "=> Committed successfully."; set_color normal
    else
        set_color red; echo "=> Commit aborted. Changes remain staged."; set_color normal
    end
end
