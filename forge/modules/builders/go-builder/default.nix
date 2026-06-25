{
  pkgs,
  packageBuilderModule,
  ...
}:
{
  imports = [
    ./options.nix
    (packageBuilderModule {
      builderName = "goPackageBuilder";
      mkDerivation = pkgs.buildGoModule;
      attrs = builder: finalAttrs: previousAttrs: {
        inherit (builder)
          vendorHash
          modRoot
          subPackages
          ldflags
          tags
          proxyVendor
          ;
      };
    })
  ];
}
