{
  home = {
    config,
    pkgs,
    env,
    myLib,
    ...
  }: {
    home.packages = [
      (myLib.withRuntimeDeps {
        targetDerivation = myLib.writeScriptBin "nix" ''
          subcommand="''${1:-}"
          bin="_nix-$subcommand"
          if [[ -n "$subcommand" ]] && which "$bin" > /dev/null 2>&1; then
            shift 1
          else
            bin="${pkgs.nix.outPath}/bin/nix"
          fi
          "$bin" "$@"
          exit $?
        '';
        binName = "nix";
        runtimeDepDerivations = [
          (myLib.writeScriptBinWithArgs "_nix-ch" ''sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch --flake "$(readlink ~/nix)#my-nixos" --impure'')
        ];
      })
    ];
    my.gc.nix.script = ''
      sudo nix store gc
      ${pkgs.home-manager}/bin/home-manager expire-generations 0
      sudo nix-collect-garbage --delete-old
      nix-collect-garbage --delete-old
    '';
  };
}
