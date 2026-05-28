{
  config,
  lib,
  pkgs,
  flakeInputs,
  system,
  ...
}:
{
  options.forge = lib.mkOption {
    description = "Module-system framework for building packages and apps (eg. NixOS VMs, or Podman containers) using those packages.";
    default = { };
    type = lib.types.submoduleWith {
      specialArgs = {
        inherit system;
        inputs = flakeInputs;
        forgeConfig = config;
        pkgs = pkgs.extend (
          finalPkgs: previousPkgs:
          # Extend `pkgs` with the `packages` from the forge.
          config.packages
          // {
            # `pkgs.pkgsOriginal` provides packages from the original `pkgs` (usually from Nixpkgs)
            # Eg. `pkgs.pkgsOriginal.offen` (Nixpkgs) and `pkgs.offen` (ngi-forge).
            # Note that as a consequence, all dependencies of those packages
            # remain those coming from the original `pkgs`,
            # even when they happen to also packaged in the forge.
            pkgsOriginal = previousPkgs;
          }
        );
      };
      modules = [
        {
          options = {

            repositoryUrl = lib.mkOption {
              type = lib.types.str;
              default = "github:ngi-nix/forge";
              description = ''
                NGI Forge repository URL.
              '';
              example = "github:ngi-nix/forge";
            };

            recipeDirs = {
              packages = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "recipes/packages";
                description = ''
                  Directory containing package recipe files.
                  Each recipe should be a recipe.nix file in a subdirectory
                  (e.g., recipes/packages/hello/recipe.nix).

                  Set to null to disable automatic package recipe loading.
                '';
                example = "recipes/packages";
              };

              apps = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "recipes/apps";
                description = ''
                  Directory containing app recipe files.
                  Each recipe should be a recipe.nix file in a subdirectory
                  (e.g., recipes/apps/my-app/recipe.nix).

                  Set to null to disable automatic app recipe loading.
                '';
                example = "recipes/apps";
              };
            };

          };
        }
      ];
    };
  };
}
