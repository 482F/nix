{
  home = {
    config,
    pkgs,
    lib,
    env,
    myLib,
    ...
  }: let
    defs = {
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
      run-command = {
        script = ''
          local setting=""
          local script=""
          local shell=""
          local name="run-command-test"
          while true; do
            if [[ ! -v 1 ]]; then
              break
            fi
            case "$1" in
              -h | --help)
                echo '  description:'
                echo '    run a shell script using `pkgs.runCommand`.'
                echo
                echo '  usage:'
                echo '    $ nix run-command <shell script>'
                echo '    $ echo <shell script> | nix run-command'
                echo '    $ echo '"'"'#!/usr/bin/env -S nix run-command --file'"'"' > test.sh; \'
                echo '      echo <shell script> >> test.sh; \'
                echo '      chmod 744 test.sh; \'
                echo '      ./test.sh'
                echo
                echo '  options:'
                echo '    -h | --help: show this help message.'
                echo '    -x | --xtrace: enable `set -x` in the shell script.'
                echo '    -s | --shell: run command and enter shell.'
                echo '    -n <name> | --name <name>: specify the derivation name. default: `run-command-test`'
                echo '    -f <file> | --name <file>: read the file as a shell script'
                exit 0
                ;;
              -x | --xtrace)
                setting="
                  set -x
                  $setting
                "
                ;;
              -s | --shell)
                shell="true"
                ;;
              -n | --name)
                shift 1
                name="$1"
                ;;
              -f | --file)
                shift 1
                script="
                  $script
                  $(cat $1)
                "
                ;;
              *)
                script="
                  $script
                  $1
                "
                ;;
            esac
            shift 1
          done

          if [[ -z "$script" ]]; then
            script="$(cat)"
          fi

          local drv="$(nix eval --impure --raw --expr '
            let
              pkgs = (import <nixpkgs> {});
              drv = pkgs.runCommand "'"$name"'" {} '"'''"'
                '"$script"'
              '"'''"';
              dummy = with builtins; (tryEval (readFileType drv.outPath)).success;
            in if dummy || true then drv.drvPath else null
          ')"'^*'

          if [[ "$drv" == '^*' ]]; then
            exit 1
          fi

          echo ----------------log---------------- >&2
          nix log $drv >&2
          echo ----------------log---------------- >&2

          nix derivation show $drv | ${pkgs.jq}/bin/jq -r 'to_entries[].value.env.out'

          if [[ "$shell" == "true" ]]; then
            nix shell $drv
          fi
        '';
      };
      which = {
        script = ''
          # TODO: ''${command-not-found-drv}/bin/command-not-found のようにしたいが、derivation が外に公開されていないため取ってこれない
          command-not-found "$1" 2>&1 | grep -Po '(?<=nix-shell -p ).+'
        '';
      };
      shell = {
        script = ''
          ${config.my.pkgs.prepend-ps1}/bin/prepend-ps1 '(nix-shell)' ${pkgs.nix}/bin/nix shell "$@"
        '';
        completion = ''
          ${pkgs.nix}/bin/nix shell "$@"
        '';
      };
      temp-writable = {
        script = ''
          local links=()
          local targets=()
          for _link in "$@"; do
            local link="$(realpath --no-symlinks "$_link")"
            local target="$(readlink "$link")"
            if [[ ! -L "$link" ]] || [[ -z "$target" ]]; then
              continue
            fi
            links+=("$link")
            targets+=("$target")
            rm "$link"
            rsync --recursive --copy-links "$target" "$(dirname "$link")"
            chmod u+w -R "$link"
            chmod u+r -R "$link"
          done
          ${config.my.pkgs.prepend-ps1}/bin/prepend-ps1 '(nix-temp-writable)' $SHELL || true
          for i in "''${!targets[@]}"; do
            local link="''${links[$i]}"
            local target="''${targets[$i]}"

            if [[ -z "$target" ]]; then
              continue
            fi

            rm -rf "$link"
            ln -s "$target" "$link"
          done
        '';
        completion = ''
          local args=("$@")
          local target="''${args[$((NIX_GET_COMPLETIONS-2))]}"
          echo filenames
          compgen -f "$target"
        '';
      };
      flake-lock-update = {
        script = ''
          local option="$(nix eval --impure --raw --expr '
            with builtins; let
              inputs = (import ./flake.nix).inputs;
              names = attrNames inputs;
              options = map (name: "--update-input ''${name}") names;
              option = concatStringsSep " " options;
            in
              option
          ')"
          nix flake lock $option
        '';
      };
    };
    cfg = config.nix.ext-subcommands;
  in {
    config = lib.mkIf cfg.enable {
      nix.ext-subcommands.subcommands = defs;
    };
  };
}
