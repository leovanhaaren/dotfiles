{ ... }:

{
  # Work packages (formerly homebrew/Brewfile.work).
  # Import from a host file to opt the machine into the work layer.
  homebrew.taps = [
    "1password/tap"
    "ankitpokhrel/jira-cli"
    "datadog-labs/pack"
  ];
  homebrew.brews = [
    "aws-vault"
    "awscli"
    "jira-cli"
    "datadog-labs/pack/pup"
  ];
  homebrew.casks = [
    "1password"
    "1password-cli"
    "session-manager-plugin"
  ];
}
