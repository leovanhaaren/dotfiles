{ ... }:

{
  # Personal machine: no work layer.
  # The attribute name in flake.nix must match this host's
  # LocalHostName (scutil --get LocalHostName); adjust both if the
  # mini reports a different name.
  networking.hostName = "mac-mini";
}
