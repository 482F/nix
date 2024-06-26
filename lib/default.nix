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
  aliasEvalFn = name: fnBody:
    builtins.listToAttrs [
      {
        inherit name;
        value = let
          script = pkgs.writeScriptBin name fnBody;
        in ''function _${name}() { eval "$(< ${script}/bin/${name})"; unset -f _${name}; }; _${name}'';
      }
    ];
  lazyNixRun = name: let
    pkgName = name.pkgName or name;
    binName = name.binName or name;
  in
    pkgs.writeScriptBin binName ''nix run nixpkgs#${pkgName} -- "''${@}"'';
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
}
