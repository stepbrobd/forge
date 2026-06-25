{
  config,
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    ./options.nix
    (packageBuilderModule (rec {
      builderName = "rustPackageBuilder";
      mkDerivation = pkgs.rustPlatform.buildRustPackage;
      attrs = builder: finalAttrs: previousAttrs: {
        inherit (config.build.${builderName})
          cargoHash
          cargoBuildFlags
          ;
      };
    }))
  ];

}
