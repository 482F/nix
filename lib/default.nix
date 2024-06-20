{pkgs ? import <nixpkgs> {}}: rec {
  writeScriptBinWithArgs = binName: script: (pkgs.writeScriptBin binName ''${script} "''${@}"'');
  withRuntimeDeps = {
    targetDerivation,
    binName,
    runtimeDepDerivations,
  }:
    (writeScriptBinWithArgs binName "${targetDerivation.outPath}/bin/${binName}")
    .overrideAttrs (attrs: {
      nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      buildCommand =
        attrs.buildCommand
        + ''
          wrapProgram $out/bin/${binName} --prefix PATH : ${pkgs.lib.makeBinPath runtimeDepDerivations}
        '';
      meta.priority = (targetDerivation.meta.priority or 5) - 1;
    });
  lazyNixRun = name: pkgs.writeScriptBin name ''nix run nixpkgs#${name} -- "''${@}"'';
  importAll = with builtins; path: map (pathStr: import (path + ("/" + pathStr))) (attrNames (readDir path));
}
