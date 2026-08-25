{
  config,
  lib,
  forge-lib,
  packageBuilderModule,
  pkgs,
  ...
}:
let
  scoping = import ./pkgs/scopes.nix { inherit lib; };

  tree = config.forge.pkgs;
  declared = config.forge.scopes;

  recipes = scoping.flatten {
    baseSet = pkgs;
    inherit declared tree;
  };
in
{
  imports = [
    ./assertions-warnings.nix
    ./builders/shared
  ];

  options.forge = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (
          { specialArgs, ... }@forgeArgs:
          {
            options.scopes = lib.mkOption {
              default = { };
              description = ''
                Package scopes.

                A scope whose name is an extensible package set of Nixpkgs
                (eg. `ocamlPackages`) is available without being declared here.
                Declaring it adds overlays to it, or points it at a different
                package set. Declaring a name Nixpkgs does not provide creates a
                new scope with `makeScope newScope`.
              '';
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  inherit specialArgs;
                  modules = [
                    {
                      options.base = lib.mkOption {
                        type = lib.types.nullOr (lib.types.functionTo lib.types.attrs);
                        default = null;
                        description = ''
                          Package set this scope extends.

                          Defaults to the package set of the same name in Nixpkgs,
                          or to an empty scope when Nixpkgs has no such name.
                        '';
                        example = lib.literalExpression "pkgs: pkgs.ocaml-ng.ocamlPackages_5_3";
                      };
                      options.overlays = lib.mkOption {
                        type = lib.types.listOf lib.types.raw;
                        default = [ ];
                        description = ''
                          Overlays applied to the scope before its packages are added.

                          Use them to patch dependencies for every package of the
                          scope at once.
                        '';
                        example = lib.literalExpression ''
                          [
                            (final: previous: {
                              ssl = previous.ssl.overrideAttrs { src = ...; };
                            })
                          ]
                        '';
                      };
                    }
                  ];
                }
              );
            };

            options.pkgs = lib.mkOption {
              default = { };
              description = ''
                Packages indexed by their `pname`, optionally nested in a scope.

                A name Nixpkgs exposes as an extensible package set, or a name
                declared in `scopes`, holds packages of that scope
                (eg. `pkgs.ocamlPackages.h3`). Every other name holds a package.

                Each package uses one of the available builders.
                Only one builder can be enabled per package by setting build.<builder>.enable = true.
              '';
              type = scoping.treeType {
                baseSet = pkgs;
                declared = forgeArgs.config.scopes;
                mkPackage =
                  scopePath:
                  lib.types.submoduleWith {
                    specialArgs = specialArgs // {
                      forgeOptions = forgeArgs.options;
                      inherit packageBuilderModule scopePath;
                      scopeName = if scopePath == [ ] then null else lib.last scopePath;
                      scope =
                        if scopePath == [ ] then specialArgs.pkgs else lib.getAttrFromPath scopePath specialArgs.pkgs;
                    };
                    modules = [
                      ./pkgs/pkg.nix
                    ];
                  };
              };
            };
          }
        )
      ];
    };
  };

  # Config section is now provided by builder modules
  config =
    let
      # Process warnings: filter to get active warnings (condition = true), then show them
      activeWarnings = lib.filter (x: x.condition) config.warnings;
      showWarnings = lib.foldr (w: acc: lib.warn w.message acc) true activeWarnings;

      # Process assertions: filter to get failed assertions (condition = false)
      failedAssertions = lib.filter (x: !x.condition) config.assertions;
      assertionMessages = lib.concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions;

      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "pkgs";
        derivations = scoping.derivationTree {
          baseSet = pkgs;
          inherit declared tree;
        };
      }) { };
    in
    {
      inherit (packagesWithNamespace) packages;

      # Collect warnings from forge.pkgs
      warnings = lib.flatten (
        map (
          { package, ... }:
          [
            {
              condition =
                package.source.hash == "" && package.source.path == null && !package.build.identityBuilder.enable;
              message = ''
                Package '${package.outputName}': source.hash is empty.
                Correct hash will be printed in the error message when package is built.
              '';
            }
            {
              condition = package.license == [ ];
              message = ''
                Package '${package.outputName}': license is empty.
              '';
            }
          ]
        ) recipes
      );

      # Collect assertions from forge.pkgs
      assertions = lib.flatten (
        map (
          { package, ... }:
          let
            builders = lib.filterAttrs (name: _: lib.hasSuffix "Builder" name) package.build;
            builderNames = map (name: "build." + name) (lib.attrNames builders);

            enabledBuilders = lib.filterAttrs (_: b: b.enable) builders;
            enabledBuilderNames = map (name: "build." + name) (lib.attrNames enabledBuilders);

            enabledBuildersCount = lib.length enabledBuilderNames;
          in
          [
            {
              condition =
                !(
                  package.source.git == null
                  && package.source.url == null
                  && package.source.path == null
                  && !package.build.identityBuilder.enable
                );
              message = ''
                Package '${package.outputName}': one of sources options must be defined.
                Available options: source.git, source.url, or source.path.
              '';
            }
            {
              condition = !(enabledBuildersCount != 1);
              message = ''
                Package '${package.outputName}': only one builder can be enabled at a time.
                Enabled options: ${lib.concatStringsSep ", " enabledBuilderNames}.
              '';
            }
            {
              condition = !(enabledBuildersCount == 0);
              message = ''
                Package '${package.outputName}': one of builder options must be enabled.
                Available options: ${lib.concatStringsSep ", " builderNames}.
              '';
            }
          ]
        ) recipes
      );

      # Evaluation check: show warnings first, then throw on failed assertions
      _module.check =
        if showWarnings then
          if failedAssertions != [ ] then throw "\nFailed assertions:\n${assertionMessages}" else true
        else
          true;
    };
}
