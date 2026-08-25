{
  config,
  lib,
  pkgs,
  self-inputs,
  forge-inputs,
  forge-lib,
  system,
  ...
}:
let
  scoping = import ./pkgs/scopes.nix { inherit lib; };
in
{
  options.forge = lib.mkOption {
    description = "Module-system framework for building packages and apps (eg. NixOS VMs, or Podman containers) using those packages.";
    default = { };
    type = lib.types.submoduleWith {
      specialArgs = {
        inherit system;
        forgeConfig = config;
        inputs = self-inputs;
        inherit forge-inputs;
        inherit forge-lib;
        # Merge the packages from the forge into the `pkgs` the recipes
        # receive. A shallow merge, not `pkgs.extend`: an overlay would rewire
        # the Nixpkgs fixpoint, so a scope overlay (eg. patching `tls` in
        # `ocamlPackages`) would silently rebuild unrelated Nixpkgs packages,
        # and would be re-applied inside nested instantiations such as
        # `pkgsi686Linux` where it cross-wires architectures.
        #
        # Scoped packages are reachable through their scope only, so that a
        # scope resolves every dependency against the same package set.
        pkgs =
          let
            extended =
              pkgs
              // scoping.looseDerivations {
                baseSet = pkgs;
                declared = config.forge.scopes;
                tree = config.forge.pkgs;
              }
              // scoping.buildScopes {
                baseSet = pkgs;
                declared = config.forge.scopes;
                tree = config.forge.pkgs;
                inherit (pkgs) newScope;
                finalPkgs = extended;
              }
              // {
                # `pkgs.pkgsOriginal` provides packages from the original `pkgs` (usually from Nixpkgs)
                # Eg. `pkgs.pkgsOriginal.offen` (Nixpkgs) and `pkgs.offen` (ngi-forge).
                # Note that as a consequence, all dependencies of those packages
                # remain those coming from the original `pkgs`,
                # even when they happen to also be packaged in the forge.
                pkgsOriginal = pkgs;
              };
          in
          extended;
        lib = lib // {
          maintainers =
            (import "${forge-inputs.nixpkgs}/maintainers/maintainer-list.nix")
            // lib.foldl' (acc: path: acc // import path) { } config.forge.maintainerLists;
        };
      };
      modules = [
        {
          options = {
            maintainerLists = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "Paths to maintainer list files in the format of Nixpkgs maintainer-list.nix.";
              example = lib.literalExpression ''
                [ inputs.ngi-forge.maintainerList
                ./maintainers/maintainer-list.nix ]
              '';
            };

            repositoryUrl = lib.mkOption {
              type = lib.types.str;
              default = "github:ngi-nix/forge";
              example = "github:ngi-nix/forge";
              description = "URL of the flake repository.";
            };
          };
        }
      ];
    };
  };
}
