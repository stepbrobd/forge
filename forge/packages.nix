{
  config,
  lib,
  pkgs,
  forge-inputs,
  flake-parts-lib,
  ...
}:

let
  evalForgeModules =
    modules:
    flake-parts-lib.evalFlakeModule {
      inputs = forge-inputs;
    } { imports = modules; };

  forgeOptionsDoc =
    modules:
    pkgs.nixosOptionsDoc {
      warningsAreErrors = false;
      options = lib.removeAttrs (evalForgeModules modules).options [ "_module" ];
      transformOptions =
        opt:
        opt
        // {
          name = lib.removePrefix "perSystem.forge." opt.name;
          declarations = [ ];
          visible = lib.match ("^perSystem\\.forge\\.(apps|packages)(\\..+)?") opt.name != null;
        };
    };

  forgeApps = config.forge.apps;
  forgeOptions = forgeOptionsDoc [
    forge-inputs.self.flakeModules.base
  ];

  # Collect app icons into a derivation
  appIcons = pkgs.runCommand "app-icons" { } ''
    mkdir -p $out
    ${lib.concatStringsSep "\n" (
      map (app: ''
        mkdir -p $out/${app.name}
        ${if app.icon or null != null then "cp ${app.icon} $out/${app.name}/icon.svg" else ""}
      '') (lib.attrValues forgeApps)
    )}
  '';
in
{
  legacyPackages = {
    # Tip(debugging): use this when not using the Flake setup (`nix repl -f.`)
    # to get a curated list of packages `pkgs.<Tab>`
    # In the Flake setup, it's equivalent to use `nix flake show`.
    # This is because simply querying `pkgs` will not display the list,
    # `pkgs` being a derivation and not an attrset of derivations
    # also in the Traditional setup to keep consistency between Flake and Traditional.
    pkgsRepl = lib.mapAttrs (packageName: package: package.result.derivation) config.forge.packages;
  };

  packages =
    let
      _forge = {
        config = pkgs.writeTextFile {
          name = "forge-config.json";
          text =
            let
              scrubConfig =
                x:
                if lib.isString x || lib.isDerivation x then
                  lib.unsafeDiscardStringContext x
                else if lib.isList x then
                  map scrubConfig x
                else if lib.isAttrs x then
                  lib.mapAttrs (n: v: scrubConfig v) x
                else
                  x;
            in
            builtins.toJSON (scrubConfig config.forge);
        };

        options = pkgs.runCommand "options.json" { } ''
          cp ${forgeOptions.optionsJSON}/share/doc/nixos/options.json $out
        '';

        ui = pkgs.callPackage ../ui/package.nix {
          inherit (config.packages) _forge;
          inherit appIcons;
          buildElmApplication = (forge-inputs.elm2nix.lib.elm2nix pkgs).buildElmApplication;
          highlight-js = pkgs.callPackage ../flake/packages/highlight-js.nix { };
        };

        ui-dev = pkgs.callPackage ../flake/packages/forge-ui-dev.nix {
          inherit (config.packages) _forge;
          highlight-js = pkgs.callPackage ../flake/packages/highlight-js.nix { };
        };

        docs = pkgs.callPackage ../flake/packages/forge-docs.nix { };

        report =
          let
            reports = import ../maintainers/mk-report.nix { inherit forgeApps pkgs lib; };
          in
          pkgs.writeShellApplication {
            name = "report-packaging";
            passthru = reports;
            text = ''
              cat <<EOF
              To generate a packaging report, use:

              \`\`\`
              nix run .#_forge.report.all      # all grants
              nix run .#_forge.report.<GRANT>  # single grant
              \`\`\`

              Available grants:
              ${lib.concatMapStringsSep "\n" (g: "- " + g) [
                "Commons"
                "Core"
                "Entrust"
                "Review"
              ]}
              EOF
            '';
          };

        announcement = pkgs.writeShellApplication {
          name = "announce-projects";
          passthru = import ../maintainers/mk-announcement.nix { inherit forgeApps pkgs lib; };
          text = ''
            cat <<EOF
            To generate project announcement, use:

            \`\`\`
            nix run .#_forge.announcement.<APP_NAME>
            \`\`\`

            Available apps:
            ${lib.concatMapStringsSep "\n" (app: "- " + app.name) (lib.attrValues forgeApps)}
            EOF
          '';
        };
      };
    in

    {
      _forge =
        let
          _forgeBundle = pkgs.linkFarm "_forge" (
            lib.mapAttrsToList (name: drv: {
              inherit name;
              path = drv;
            }) _forge
          );
          mkDummyGroup =
            name:
            _forge
            // {
              inherit name;
              type = "derivation";
              inherit (pkgs.stdenv.hostPlatform) system;
              inherit (_forgeBundle) drvPath outPath outputName;
              # In case flake schemas ever gets merged this will be useful
              # if using `lix` you can see this description in the output of `nix flake show`
              meta.description = "Build all _forge at once";
            };
        in
        mkDummyGroup "_forge";
    }
    // lib.mapAttrs' (name: lib.nameValuePair "_forge.${name}") _forge;

}
