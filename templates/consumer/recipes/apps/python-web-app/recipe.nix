{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "python-web-app";
  description = lib.mkForce "Example web API with database backend (extended).";

  services.runtimes.nixos.nixosConfig = {
    environment.systemPackages = [
      pkgs.postgresql
    ];
  };
}
