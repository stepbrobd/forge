# From Nixpkgs' buildDunePackage:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/ocaml/dune.nix

{
  lib,
  ...
}:

{
  options = {
    enable = lib.mkEnableOption ''
      OCaml builder for applications and libraries.

      Uses `buildDunePackage` from Nixpkgs, which builds OCaml packages with
      Dune and installs them through findlib.

      A package declared under an OCaml scope (eg. `pkgs.ocamlPackages.h3`)
      builds against that scope. A package declared outside any scope builds
      against `pkgs.ocamlPackages`.

      For more information, see the
      [Nixpkgs OCaml documentation](https://nixos.org/manual/nixpkgs/unstable/#sec-language-ocaml)
    '';

    minimalVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Minimal OCaml version required to build the package.

        The build fails early with an explicit message when `ocamlPackages` provides an
        older compiler.

        Mapped to `minimalOCamlVersion`.
      '';
      example = "4.12";
    };

    packages = {
      dependencies = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of dependencies that must be propagated to downstream consumers.

          OCaml libraries linked by dependents belong here, so that findlib can
          resolve them transitively.

          Mapped to `propagatedBuildInputs`.
        '';
        example = lib.literalExpression "with pkgs.ocamlPackages; [ menhirLib yojson ]";
      };
    };
  };
}
