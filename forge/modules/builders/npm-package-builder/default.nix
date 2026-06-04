{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    ./options.nix
    (packageBuilderModule {
      builderName = "npmPackageBuilder";
      mkDerivation = pkgs.buildNpmPackage;
      attrs = builder: finalAttrs: previousAttrs: {
        nativeBuildInputs = previousAttrs.nativeBuildInputs or [ ] ++ [
          pkgs.nodejs
        ];
        inherit (builder)
          npmDepsHash
          npmInstallFlags
          ;
      };
    })
  ];
}
