{ ... }:

{
  networking.hostName = "MacBook-Pro-van-Leo";

  # Work packages (Brewfile.work) belong to this machine.
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
