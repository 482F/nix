{
  config,
  pkgs,
  env,
  myLib,
  ...
}: {
  home.packages = [
    (myLib.withRuntimeDeps {
      targetDerivation = pkgs.writeScriptBin "nix" ''
        subcommand="''${1:-}"
        bin=""
        if [[ -n "$subcommand" ]] && which "nix-$subcommand" > /dev/null 2>&1; then
          bin="nix-$subcommand"
          shift 1
        else
          bin="${pkgs.nix.outPath}/bin/nix"
        fi
        "$bin" "$@"
        exit $?
      '';
      binName = "nix";
      runtimeDepDerivations = [
        (pkgs.writeScriptBin "nix-sw" ''sudo nixos-rebuild switch --flake "$(readlink ~/nix)#my-nixos" --impure'')
      ];
    })
  ];
}
