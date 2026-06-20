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

      For more information, see the
      [Nixpkgs OCaml documentation](https://nixos.org/manual/nixpkgs/unstable/#sec-language-ocaml)
    '';

    scope = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      default = pkgs: pkgs.ocaml-ng.ocamlPackages;
      defaultText = lib.literalExpression "pkgs: pkgs.ocaml-ng.ocamlPackages";
      description = ''
        The OCaml package scope providing the builder and the dependencies.

        Override to build against a different OCaml compiler version. All
        dependencies must be taken from the same scope, otherwise they are
        compiled for an incompatible compiler version.
      '';
      example = lib.literalExpression "pkgs: pkgs.ocaml-ng.ocamlPackages_latest";
    };

    minimalVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Minimal OCaml version required to build the package.

        The build fails early with an explicit message when `scope` provides an
        older compiler.

        Mapped to `minimalOCamlVersion`.
      '';
      example = "4.12";
    };

    packages = {
      dep = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of dependencies that must be propagated to downstream consumers.

          OCaml libraries linked by dependents belong here, so that findlib can
          resolve them transitively.

          Mapped to `propagatedBuildInputs`.
        '';
        example = lib.literalExpression "with pkgs.ocaml-ng.ocamlPackages; [ menhirLib yojson ]";
      };
    };
  };
}
