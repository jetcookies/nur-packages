# helpers/update.nix
# Run `passthru.updateScript` of this repository's own packages.
#
# Modeled after xddxdd/nur-packages' helpers/update.nix, trimmed to this
# repository's flat package layout.
#
# Usage:
#   nix-shell helpers/update.nix                                  # update everything
#   nix-shell helpers/update.nix --argstr packages "rime-lmdg typewords"
#   nix-shell helpers/update.nix --arg excludes '[ "typewords" ]'   # skip some
{
  pkgs ? import <nixpkgs> { },
  # Space-separated package names to update; empty means all packages.
  packages ? "",
  # Package names to leave alone (you update them yourself); they carry an
  # updateScript but are skipped here.
  excludes ? [ ],
}:

let
  inherit (builtins) elem hasAttr isAttrs removeAttrs;
  inherit (pkgs) lib;

  # The repository's own packages (root default.nix), minus the special
  # `lib`/`modules`/`overlays` attributes.
  repoPkgs = removeAttrs (import ../default.nix { inherit pkgs; }) [
    "lib"
    "modules"
    "overlays"
  ];

  # Normalize `passthru.updateScript` to a command list, or null if absent.
  # Accepted shapes (nixpkgs convention): a path/string, a list, an attrset
  # with a `command` field, or a derivation.
  scriptOf = pkg:
    let
      script = (pkg.passthru or { }).updateScript or null;
    in
    if script == null then
      null
    else if lib.isDerivation script then
      [ (toString script) ]
    else if isAttrs script then
      if script ? command then map toString (lib.toList script.command) else null
    else
      map toString (lib.toList script);

  # Repository derivations that actually carry an update script.
  scripted = lib.filterAttrs (name: pkg: lib.isDerivation pkg && scriptOf pkg != null) repoPkgs;

  # ... minus the ones you manage yourself.
  candidates = lib.filterAttrs (name: _: !elem name excludes) scripted;

  requested = lib.filter (s: s != "") (lib.splitString " " packages);

  excludedRequested = lib.filter (name: elem name excludes && hasAttr name scripted) requested;
  unknown = lib.filter (name: !hasAttr name scripted) requested;

  selected =
    if requested != [ ] then
      lib.filterAttrs (name: _: elem name requested) candidates
    else
      candidates;

  # Runnable packages skipped because they are in `excludes` (informational).
  skipped = lib.filter (name: elem name excludes && hasAttr name scripted) (builtins.attrNames scripted);

  # Passed as JSON: embedding store paths in the hook text directly would
  # break if they are not inputs of this derivation.
  packagesJson = pkgs.writeText "update-packages.json" (builtins.toJSON (
    lib.mapAttrsToList (attrName: pkg: {
      attrPath = attrName;
      name = pkg.name;
      pname = lib.getName pkg;
      oldVersion = lib.getVersion pkg;
      updateScript = scriptOf pkg;
    }) selected
  ));

  helpText = ''
    No package with a passthru.updateScript was selected.
    Candidates: ${lib.concatStringsSep ", " (builtins.attrNames candidates)}
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  name = "nur-update";
  nativeBuildInputs = [
    pkgs.git
    pkgs.cacert
    pkgs.jq
  ];
  buildCommand = ''
    echo "Run this via \`nix-shell ${toString ./.}\` instead of nix-build." >&2
    exit 1
  '';
  shellHook = ''
    unset shellHook

    ${lib.optionalString (excludedRequested != [ ]) ''
      echo "Excluded by \`excludes\` (remove from the list to run): ${lib.concatStringsSep " " excludedRequested}" >&2
      exit 1
    ''}

    ${lib.optionalString (unknown != [ ]) ''
      echo "No updateScript for: ${lib.concatStringsSep " " unknown}" >&2
      exit 1
    ''}

    ${lib.optionalString (selected == { }) ''
      echo "${helpText}" >&2
      exit 1
    ''}

    ${lib.optionalString (skipped != [ ]) ''
      echo "Skipped (excludes): ${lib.concatStringsSep " " skipped}"
    ''}

    # Run update scripts from the repository root so they can edit files in place.
    cd "${toString ./.}/.."

    FAILED=""
    while IFS= read -r PKG; do
      ATTR=$(jq -r .attrPath <<<"$PKG")
      OLD=$(jq -r .oldVersion <<<"$PKG")
      CMD=$(jq -r '.updateScript | map(@sh) | join(" ")' <<<"$PKG")
      echo ">>> $ATTR: updating ($OLD)"
      if env \
          UPDATE_NIX_ATTR_PATH="$ATTR" \
          UPDATE_NIX_NAME="$(jq -r .name <<<"$PKG")" \
          UPDATE_NIX_PNAME="$(jq -r .pname <<<"$PKG")" \
          UPDATE_NIX_OLD_VERSION="$OLD" \
          bash -c "$CMD"; then
        echo ">>> $ATTR: done"
      else
        echo ">>> $ATTR: FAILED" >&2
        FAILED="$FAILED $ATTR"
      fi
    done < <(jq -c '.[]' "${packagesJson}")

    if [ -n "$FAILED" ]; then
      echo "Failed:$FAILED" >&2
      exit 1
    fi
    echo "All update scripts finished successfully."
    exit 0
  '';
}
