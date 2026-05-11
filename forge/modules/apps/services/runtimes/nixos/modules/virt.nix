{
  config,
  lib,
  ...
}:

{
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  virtualisation = {
    graphics = false;

    inherit (config.vm)
      cores
      diskSize
      memorySize
      ;

    # Pass entropy from host to VM to prevent slow service startup due to entropy starvation.
    qemu.options = [ "-device virtio-rng-pci" ];

    forwardPorts = map (
      portRange:
      if builtins.isString portRange then
        let
          portSplit = lib.splitString ":" portRange;
        in
        {
          from = "host";
          host.port = lib.toInt (lib.elemAt portSplit 0);
          guest.port = lib.toInt (lib.elemAt portSplit 1);
        }
      else
        portRange
    ) config.vm.forwardPorts;
  };
}
