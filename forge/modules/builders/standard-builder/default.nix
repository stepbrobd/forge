{
  config,
  packageBuilderModule,
  ...
}:
{
  imports = [
    ./options.nix
    (packageBuilderModule {
      builderName = "standardBuilder";
      mkDerivation = config.build.standardBuilder.stdenv.mkDerivation;
      attrs =
        builder: finalAttrs: previousAttrs:
        { };
    })
  ];
}
