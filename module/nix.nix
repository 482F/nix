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

          ngc="''${NIX_GET_COMPLETIONS:-}"
          if [[ "$ngc" != "1" ]] && [[ -n "$subcommand" ]] && which "$bin" > /dev/null 2>&1; then
            shift 1
          else
            bin="${pkgs.nix.outPath}/bin/nix"
          fi
          "$bin" "$@"
          code=$?

          if [[ "$ngc" == "1" ]]; then
            compgen -A command _nix-$subcommand | sed 's/^_nix-//g'
          fi

          exit $code
        '';
        binName = "nix";
        runtimeDepDerivations = with builtins;
          attrValues (mapAttrs (subcommand: {
              script,
              completion ? ":",
            }:
              myLib.writeScriptBin "_nix-${subcommand}" ''
                function comp() {
                  ${completion}
                }
                function main() {
                  ${script}
                }
                if [[ "''${NIX_GET_COMPLETIONS:-}" != "" ]]; then
                  comp "$@"
                  exit 0
                fi

                main "$@"
              '')
            {
              ch = {
                script = ''sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch --flake "$(readlink ~/nix)#my-nixos" --impure'';
              };
            });
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
