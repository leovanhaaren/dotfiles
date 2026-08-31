{ config, lib, ... }:

let
  # Live checkout of this repository. Links point here (not into the
  # Nix store) so edits take effect without a rebuild, matching the
  # Stow workflow. Override per host if the checkout lives elsewhere.
  dotfilesDir = "${config.home.homeDirectory}/Workspaces/leovanhaaren/dotfiles";

  link = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
  };

  # Mirror `stow --no-folding`: link every tracked file individually
  # and leave directories real, so machine-local files written next to
  # them (gh hosts.yml, fish_variables, nvim lazy-lock.json) stay in
  # $HOME and never land in the repository. readDir sees the flake's
  # git-tracked tree, so new files are picked up on the next rebuild.
  filesUnder = dir: prefix:
    lib.flatten (lib.mapAttrsToList
      (name: type:
        if type == "directory"
        then filesUnder (dir + "/${name}") "${prefix}${name}/"
        else [ "${prefix}${name}" ])
      (builtins.readDir dir));

  linkAll = paths: lib.genAttrs paths link;
in
{
  home.file = linkAll ([
    ".aliases"
    ".functions"
    ".gitconfig"
    ".gitmux.conf"
    ".tmux.conf"
    ".zprofile"
    ".zshrc"
  ]
  ++ filesUnder ../../bin "bin/"
  ++ filesUnder ../../.config ".config/");
}
