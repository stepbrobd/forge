{
  pkgs,
  ...
}:

{
  apps.naja = {
    displayName = "Naja";
    description = "EDA tool focused on post logic synthesis.";
    usage = ''
      Naja provides a structural netlist API and tools for EDA post-synthesis flows,
      including netlist editing, optimization, and analysis.

      Show available Naja commands

      ```bash
      naja_edit --help
      ```
    '';

    links = {
      source = "https://github.com/najaeda/naja";
      docs = "https://najaeda.github.io/naja/";
    };

    ngi.grants = {
      Entrust = [
        "Naja"
        "Naja-DNL"
      ];
    };

    programs = {
      packages = [
        pkgs.naja
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      naja_edit --stats
      grep -q "naja version" naja_stats.log
    '';
  };
}
