{
  pkgs,
  ...
}:
{
  pkgs.python3Packages.padne.build.identityBuilder = {
    enable = true;
    # TODO: replace with Nixpkgs derivation when it's merged:
    # https://github.com/NixOS/nixpkgs/pull/549111
    derivation = pkgs.python3Packages.callPackage ./_padne.nix { };
  };
  pkgs.padne.build.identityBuilder = {
    enable = true;
    # TODO: replace with Nixpkgs derivation when it's merged:
    # https://github.com/NixOS/nixpkgs/pull/549111
    derivation = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.padne;
  };
}
