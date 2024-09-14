{
  home = {
    config,
    pkgs,
    lib,
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
        runtimeDepDerivations =
          lib.mapAttrsToList (subcommand: {
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
              script = ''sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch --flake "$(readlink ~/nix)#my-nixos" --impure "$@"'';
            };
            p = let
              preScript = ''
                subcommand="''${1:-}"
                shift 1

                function f-nix-search() {
                  nix "$subcommand" nixpkgs "$@"
                }

                function f-nix-shell() {
                  local hyphened=false
                  local -a nargs=()
                  for arg in "$@"; do
                    if [[ "$arg" == "--" ]]; then
                      hyphened="true"
                    fi

                    if [[ "$hyphened" == "true" ]] || [[ "$arg" == "-"* ]]; then
                      nargs+=("$arg")
                    else
                      nargs+=("nixpkgs#$arg")
                    fi
                  done
                  nix "$subcommand" "''${nargs[@]}"
                }

                function f-nix-run() {
                  local target="''${1:-}"
                  shift 1
                  nix "$subcommand" "nixpkgs#$target" "$@"
                }
              '';
            in {
              script = ''
                ${preScript}
                f-nix-$subcommand $@
              '';
              completion = ''
                ${preScript}
                export NIX_GET_COMPLETIONS="$((NIX_GET_COMPLETIONS-1))"

                result="$(f-nix-$subcommand $@)"

                if [[ "$subcommand" == "search" ]]; then
                  echo "$result"
                else
                  echo "$result" | sed 's/^nixpkgs#//g'
                fi
              '';
            };
            gcm = {
              script = ''
                # TODO: ''${command-not-found-drv}/bin/command-not-found のようにしたいが、derivation が外に公開されていないため取ってこれない
                command-not-found "$1" 2>&1 | grep -Po '(?<=nix-shell -p ).+'
              '';
            };
          };
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
