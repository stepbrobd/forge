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
      name = "pythonPackageBuilder";
      imports = ./options.nix;
      mkDerivation = pythonPackages.buildPythonPackage;
      attrs = builder: finalAttrs: previousAttrs: {
        format = "pyproject";
        inherit (builder)
          disabledTests
          ;
        inherit (builder.packages)
          build-system
          dependencies
          optional-dependencies
          ;
        pythonImportsCheck = builder.importsCheck;
        pythonRelaxDeps = builder.relaxDeps;
      };
    })
  ];
}
