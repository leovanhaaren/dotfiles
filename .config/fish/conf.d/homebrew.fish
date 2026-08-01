# Homebrew (macOS)
set -gx HOMEBREW_TEMP /private/var/db/homebrew/tmp
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end
