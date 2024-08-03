{pkgs ? import <nixpkgs> {}}: rec {
  writeScriptBin = binName: script: (pkgs.writeScriptBin binName ''
    #!/usr/bin/env bash

    set -ue -o pipefail

    ${script}
  '');
  writeScriptBinWithArgs = binName: script: (writeScriptBin binName ''${script} "$@"'');
  writeBgScriptBin = binName: script: (
    let
      scriptPath = (writeScriptBin binName ''${script} "$@"'').outPath;
    in
      writeScriptBin binName ''
        command="${scriptPath}/bin/${binName}"
        if [[ "''${1:-}" == "--fg" ]]; then
          shift 1
          "$command" "$@"
        else
          nohup "$command" "$@" > /dev/null 2>&1 &
        fi
      ''
  );
  withRuntimeDeps = {
    targetDerivation,
    binName,
    runtimeDepDerivations ? [],
    runtimeDepPaths ? [],
  }:
    (writeScriptBinWithArgs binName "${targetDerivation.outPath}/bin/${binName}")
    .overrideAttrs (attrs: {
      nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      buildCommand =
        attrs.buildCommand
        + ''
          wrapProgram $out/bin/${binName} --prefix PATH : ${pkgs.lib.makeBinPath runtimeDepDerivations}
        ''
        + (
          with builtins;
            concatStringsSep "\n" (
              map (path: "wrapProgram $out/bin/${binName} --prefix PATH : ${path}")
              runtimeDepPaths
            )
        );
      meta.priority = (targetDerivation.meta.priority or 5) - 1;
    });
  aliasEvalFn = name: fnBody:
    builtins.listToAttrs [
      {
        inherit name;
        value = let
          script = writeScriptBin name fnBody;
        in ''function _${name}() { eval "$(< ${script}/bin/${name})"; unset -f _${name}; }; _${name}'';
      }
    ];
  lazyNixRun = name: let
    pkgName = name.pkgName or name;
    binName = name.binName or name;
  in
    writeScriptBin binName ''nix run nixpkgs#${pkgName} -- "$@"'';
  importAll = with builtins;
    path:
      pkgs.lib.lists.flatten (attrValues (mapAttrs (
        pathStr: type: let
          fullPath = path + ("/" + pathStr);
        in
          if type == "directory"
          then importAll fullPath
          else import fullPath
      ) (readDir path)));

  # `imports = [(myLib.gitClone { ... })]`
  gitClone = {
    homeManagerLib,
    cloneRemote,
    finalRemote ? cloneRemote,
    dist,
  }: {
    home.activation = builtins.listToAttrs [
      {
        name = "git-clone-" + dist;
        value = homeManagerLib.dag.entryAfter ["writeBoundary"] ''
          function _() {
            if [[ -d '${dist}' ]]; then
              return 0
            fi
            NIX_SSL_CERT_FILE='/etc/ssl/certs/ca-certificates.crt' run nix shell nixpkgs#git nixpkgs#openssh --command git clone '${cloneRemote}' '${dist}'
            cd '${dist}'
            run nix shell nixpkgs#git --command git remote set-url origin '${finalRemote}'
          }
          _; unset -f _
        '';
      }
    ];
  };
  filterAttrs = f: set:
    with builtins;
      listToAttrs
      (
        filter
        (entry: f entry.neme entry.value)
        (attrValues (mapAttrs (name: value: {inherit name value;}) set))
      );
}
