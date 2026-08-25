# Package scoping.
#
# A name under `forge.pkgs` denotes a scope when the base package set exposes it
# as an extensible package set, or when `forge.scopes` declares it. Every other
# name denotes a package recipe. Discrimination never inspects the shape of a
# definition, so a scope member may be named after a package option.
{ lib }:

let
  # nixpkgs aliases throw on access, probing a name must not propagate that
  isExtensibleName =
    set: name:
    let
      probe = builtins.tryEval (
        let
          value = set.${name} or null;
        in
        lib.isAttrs value && !lib.isDerivation value && (value ? overrideScope || value ? extend)
      );
    in
    probe.success && probe.value;

  tryGet =
    set: name:
    let
      probe = builtins.tryEval (set.${name} or null);
    in
    if probe.success then probe.value else null;
in

rec {
  isScopeName =
    { baseSet, declared }:
    name: declared ? ${name} || isExtensibleName baseSet name;

  # every scope that must exist in the extended package set, declared or inferred
  scopeNames =
    {
      baseSet,
      declared,
      tree,
    }:
    lib.unique (
      lib.attrNames declared
      ++ lib.filter (isScopeName { inherit baseSet declared; }) (lib.attrNames tree)
    );

  # recipes reachable from a node, paired with their attribute path
  flatten =
    {
      baseSet,
      declared,
      tree,
    }:
    lib.concatLists (
      lib.mapAttrsToList (
        name: node:
        if isScopeName { inherit baseSet declared; } name then
          map (entry: entry // { path = [ name ] ++ entry.path; }) (flatten {
            baseSet = tryGet baseSet name;
            declared = { };
            tree = node;
          })
        else
          [
            {
              path = [ name ];
              package = node;
            }
          ]
      ) tree
    );

  # nested attribute set mirroring the recipe tree, holding derivations
  derivationTree =
    {
      baseSet,
      declared,
      tree,
    }:
    lib.mapAttrs (
      name: node:
      if isScopeName { inherit baseSet declared; } name then
        derivationTree {
          baseSet = tryGet baseSet name;
          declared = { };
          tree = node;
        }
      else
        node.result.derivation
    ) tree;

  # packages defined outside any scope
  looseDerivations =
    {
      baseSet,
      declared,
      tree,
    }:
    lib.mapAttrs (_: package: package.result.derivation) (
      lib.filterAttrs (name: _: !isScopeName { inherit baseSet declared; } name) tree
    );

  # scope contents: member derivations plus nested scopes
  members =
    {
      baseSet,
      declared,
      tree,
      newScope,
    }:
    lib.mapAttrs (
      name: node:
      if isScopeName { inherit baseSet declared; } name then
        buildScope {
          inherit
            baseSet
            declared
            newScope
            name
            ;
          tree = node;
        }
      else
        node.result.derivation
    ) tree;

  buildScope =
    {
      baseSet,
      declared,
      tree,
      name,
      newScope,
      finalPkgs ? null,
    }:
    let
      scope = declared.${name} or { };
      childBase = tryGet baseSet name;

      base =
        if scope.base or null != null then
          scope.base finalPkgs
        else if isExtensibleName baseSet name then
          childBase
        else
          lib.makeScope newScope (_: { });

      overrideScope = base.overrideScope or base.extend;

      memberOverlay =
        scopeFinal: _:
        members {
          baseSet = childBase;
          declared = { };
          inherit tree;
          # a scope nested further down is allocated with this scope's newScope
          newScope = scopeFinal.newScope or newScope;
        };
    in
    overrideScope (lib.composeManyExtensions ((scope.overlays or [ ]) ++ [ memberOverlay ]));

  buildScopes =
    {
      baseSet,
      declared,
      tree,
      newScope,
      finalPkgs,
    }:
    lib.genAttrs (scopeNames { inherit baseSet declared tree; }) (
      name:
      buildScope {
        inherit
          baseSet
          declared
          newScope
          name
          finalPkgs
          ;
        tree = tree.${name} or { };
      }
    );

  # `forge.pkgs` type: an attribute set whose members are recipes or scopes
  treeType =
    args@{
      baseSet,
      declared,
      mkPackage,
      scopePath ? [ ],
    }:
    lib.types.lazyAttrsOf (nodeType args);

  nodeType =
    args@{
      baseSet,
      declared,
      mkPackage,
      scopePath ? [ ],
    }:
    let
      resolve =
        name:
        if isScopeName { inherit baseSet declared; } name then
          treeType {
            baseSet = tryGet baseSet name;
            declared = { };
            inherit mkPackage;
            scopePath = scopePath ++ [ name ];
          }
        else
          mkPackage scopePath;
    in
    lib.mkOptionType {
      name = "forgeRecipeOrScope";
      description = "package recipe or package scope";
      descriptionClass = "noun";
      check = value: lib.isAttrs value || lib.isFunction value || lib.types.path.check value;
      merge = loc: defs: (resolve (lib.last loc)).merge loc defs;
      # a scope reuses the recipe options, so documentation renders them once
      getSubOptions = prefix: (mkPackage scopePath).getSubOptions prefix;
      getSubModules = null;
      substSubModules = _: nodeType args;
      nestedTypes.recipe = mkPackage scopePath;
    };
}
