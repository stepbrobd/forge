{
  config,
  lib,
  name,
  specialArgs,
  ...
}:
{
  options = {
    # This internal option allows us to share this exact same logic
    # between apps and packages by dynamically accessing `specialArgs.forgeOptions.${config._recipeType}`
    _recipeType = lib.mkOption {
      type = lib.types.enum [
        "apps"
        "pkgs"
      ];
      internal = true;
      description = "Internal type to distinguish between apps and pkgs for metadata resolution.";
    };

    _recipeScope = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      internal = true;
      description = "Attribute path of the enclosing scope, empty for unscoped recipes.";
    };

    recipePath = lib.mkOption {
      type = lib.types.str;
      default =
        let
          # a definition carries a position only for the recipes it declares,
          # `abort` from getAttrFromPath is not catchable so attrByPath is used
          locs = map (
            def:
            let
              enclosing = lib.attrByPath config._recipeScope null def.value;
            in
            if enclosing == null then null else builtins.unsafeGetAttrPos name enclosing
          ) specialArgs.forgeOptions.${config._recipeType}.definitionsWithLocations;
          validLocs = builtins.filter (loc: loc != null) locs;
          absPath = if validLocs != [ ] then (builtins.head validLocs).file else "";
        in
        if absPath == "" then
          ""
        else
          let
            match = builtins.match "^/nix/store/[a-z0-9]+-[^/]+/(.*)$" absPath;
          in
          if match != null then builtins.head match else absPath;
      internal = true;
      description = "Relative file path pointing to the recipe definition.";
    };
  };
}
