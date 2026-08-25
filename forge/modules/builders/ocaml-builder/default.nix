{
  lib,
  pkgs,
  scope,
  scopeName,
  packageBuilderModule,
  ...
}:

let
  # a scoped package builds against its own scope, so every dependency it
  # resolves comes from the same OCaml compiler
  ocamlPackages = if scopeName == null then pkgs.ocamlPackages else scope;
in

{
  imports = [
    (packageBuilderModule {
      name = "ocamlBuilder";
      imports = ./options.nix;
      mkDerivation = ocamlPackages.buildDunePackage;
      attrs =
        builder: finalAttrs: previousAttrs:
        {
          propagatedBuildInputs = builder.packages.dependencies;

          env = (previousAttrs.env or { }) // {
            DUNE_CACHE = "disabled";
          };
        }
        // lib.optionalAttrs (builder.minimalVersion != null) {
          minimalOCamlVersion = builder.minimalVersion;
        };
    })
  ];
}
