{pkgs ? import <nixpkgs> {}}: rec {
  writeScriptBin = binName: script: (pkgs.writeScriptBin binName ''
    #!${pkgs.bash}/bin/bash

    set -ue -o pipefail

    ${script}
  '');
  writeScriptBinWithArgs = binName: script: (writeScriptBin binName ''${script} "$@"'');
  writeBgScriptBin = binName: script: (
    let
      scriptPath = (writeScriptBin binName ''${script}'').outPath;
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
    .overrideAttrs (attrs: let
      paths = builtins.concatStringsSep ":" ([(pkgs.lib.makeBinPath runtimeDepDerivations)] ++ runtimeDepPaths);
    in {
      nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      buildCommand =
        attrs.buildCommand
        + ''
          wrapProgram $out/bin/${binName} --prefix PATH : ${paths}
        '';
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
      builtins.filter (value: value != null) (pkgs.lib.lists.flatten (pkgs.lib.mapAttrsToList (
        pathStr: type: let
          fullPath = path + ("/" + pathStr);
        in
          if type == "directory"
          then importAll fullPath
          else if (pkgs.lib.strings.hasSuffix ".nix" fullPath)
          then import fullPath
          else null
      ) (readDir path)));

  mkWinDerivation = {
    sourceDerivation,
    storeDir,
  }: let
    dest = "${storeDir}/${sourceDerivation.name}";
  in {
    activation = ''
      mkdir -p ${dest}
      ${pkgs.rsync}/bin/rsync --recursive --del --checksum --links ${sourceDerivation}/ ${dest}/
    '';
    derivation = pkgs.runCommand sourceDerivation.name {} ''
      mkdir -p $out
      while read -u 10 target; do
        if [[ -d ${sourceDerivation}/$target ]]; then
          mkdir -p $out/$target
        else
          ln -s ${dest}/$target $out/$target
        fi
      done 10< <(cd ${sourceDerivation}; ${pkgs.findutils}/bin/find .)
    '';
  };
}
