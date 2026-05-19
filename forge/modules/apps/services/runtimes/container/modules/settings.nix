{
  app,

  service,
  componentConfig ? {
    setup = "";
    packages = [ ];
    imageConfig = { };
  },
  pkgs,
  lib,
  ...
}:
{
  binName = "${app.name}-service";

  container = {
    copyToRoot = pkgs.buildEnv {
      name = "runtime-bins";
      paths = componentConfig.packages;
      pathsToLink = [ "/bin" ];
    };

    imageConfig = componentConfig.imageConfig // {
      Env =
        let
          # { K = "V"; } -> [ "K=V" ]
          envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;

          # imageConfig.Env follows OCI spec: list of "K=V" strings
          containerEnv = lib.listToAttrs (
            map (
              envPair:
              let
                parts = lib.splitString "=" envPair;
              in
              {
                name = lib.head parts;
                value = lib.concatStringsSep "=" (lib.tail parts);
              }
            ) (componentConfig.imageConfig.Env or [ ])
          );

          # NOTE: we merge Attrs to remove duplicate keys
          envList = service.environment // containerEnv;
        in
        envAttrsToList envList;
    };
  };

  startup.runOnStartup = lib.mkIf (componentConfig.setup != "") (
    pkgs.writeShellScript "container-setup" componentConfig.setup
  );
}
