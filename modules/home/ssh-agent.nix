{ ... }:

{
  # Mirrors launchd/nl.leovanhaaren.ssh-auth-sock.plist, which mac.sh
  # installs on the classic path: point SSH_AUTH_SOCK at the Proton Pass
  # SSH agent for everything launchd starts after login. Git's SSH
  # commit signing reads only SSH_AUTH_SOCK, not ~/.ssh/config.
  launchd.agents."nl.leovanhaaren.ssh-auth-sock" = {
    enable = true;
    config = {
      # Same label as the classic plist, so switching paths replaces it.
      Label = "nl.leovanhaaren.ssh-auth-sock";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''/bin/launchctl setenv SSH_AUTH_SOCK "$HOME/.ssh/proton-pass-ssh-agent.sock"''
      ];
      RunAtLoad = true;
    };
  };
}
