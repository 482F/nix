{
  home = {
    config,
    pkgs,
    lib,
    env,
    myLib,
    ...
  }: let
    cfg = config.nix.ext-subcommands;
  in {
    options.nix.ext-subcommands = let
      inherit (lib) mkOption mkEnableOption types;
    in {
      enable = mkEnableOption "";
      subcommands = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            script = mkOption {
              type = types.str;
            };
            completion = mkOption {
              type = types.str;
              default = ":";
            };
          };
        });
      };
    };

    config = lib.mkIf cfg.enable {
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
          runtimeDepDerivations = lib.pipe cfg.subcommands [
            (lib.filterAttrs (name: _: cfg.subcommands.${name}.enable))
            (lib.mapAttrsToList (
              subcommand: {
                script,
                completion ? ":",
                ...
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
                ''
            ))
          ];
        })
      ];
    };
  };
}
