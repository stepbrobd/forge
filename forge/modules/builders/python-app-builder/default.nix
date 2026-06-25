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
      builderName = "pythonAppBuilder";
      mkDerivation = pkgs.python3Packages.buildPythonApplication;
      attrs =
        builder: finalAttrs: previousAttrs:
        let
          builder = config.build.${builderName};
        in
        {
          format = "pyproject";
          inherit (builder.packages)
            build-system
            dependencies
            optional-dependencies
            ;
          inherit (builder)
            disabledTests
            ;
          # Warning(consistency): such renames are not done elsewhere,
          # eg. in `packages.${package}.build.npmPackageBuilder.npmDepsHash`
          pythonImportsCheck = builder.importsCheck;
          pythonRelaxDeps = builder.relaxDeps;
        };
    }))
  ];
}
