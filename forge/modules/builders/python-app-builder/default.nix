{
  pkgs,
  scope,
  scopeName,
  packageBuilderModule,
  ...
}:

let
  # a scoped package builds against its own scope, so every dependency it
  # resolves comes from the same interpreter
  pythonPackages = if scopeName == null then pkgs.python3Packages else scope;
in

{
  imports = [
    (packageBuilderModule {
      name = "pythonAppBuilder";
      imports = ./options.nix;
      mkDerivation = pythonPackages.buildPythonApplication;
      attrs = builder: finalAttrs: previousAttrs: {
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
        # eg. in `pkgs.${package}.build.npmPackageBuilder.npmDepsHash`
        pythonImportsCheck = builder.importsCheck;
        pythonRelaxDeps = builder.relaxDeps;
      };
    })
  ];
}
