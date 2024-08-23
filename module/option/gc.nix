{
  home = {
    config,
    lib,
    pkgs,
    user,
    myLib,
    ...
  }: let
    inherit (lib) mkOption types;
  in {
    options = {
      my.gc = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            script = mkOption {type = types.lines;};
          };
        });
      };
    };

    config.home.packages = let
      gcs = lib.filterAttrs (name: value: value.enable && (value.script or null != null)) config.my.gc;
    in
      if builtins.length (builtins.attrValues gcs) <= 0
      then []
      else let
        runtimeDepDerivations = (
          lib.mapAttrsToList (name: {script, ...}: myLib.writeScriptBin "_mygc-${name}" script) gcs
        );
        wr = binName: targetDerivation:
          myLib.withRuntimeDeps {
            inherit binName targetDerivation runtimeDepDerivations;
          };
        bin = wr "mygc-bin" (myLib.writeScriptBin "mygc-bin" ''
          commands=""
          if [[ "''${1:-}" = "all" ]]; then
            commands="$(compgen -A command _mygc-)"
          else
            commands="$(echo " $@" | sed 's/\s/ _mygc-/g')"
          fi
          for command in $commands; do
            $command
          done
        '');
        # wrapProgram したスクリプトを source すると落ちるので回避
        comp = pkgs.writeScriptBin "mygc-comp" ''
          _mygc() {
              local cword=''${COMP_CWORD:-0}
              local cur=''${COMP_WORDS[cword]:-}
              mapfile -t COMPREPLY < <(compgen -W 'all ${builtins.concatStringsSep " " (builtins.attrNames gcs)}' -- "$cur")
          } &&
          complete -F _mygc mygc
        '';
      in [
        (pkgs.stdenv.mkDerivation {
          pname = "mygc";
          version = "0.0.1";
          buildCommand = ''
            bin_dest=$out/bin
            mkdir -p $bin_dest
            cp ${bin}/bin/mygc-bin $bin_dest/mygc

            comp_dest=$out/share/bash-completion/completions
            mkdir -p $comp_dest
            cp ${comp}/bin/mygc-comp $comp_dest/mygc
          '';
        })
      ];
  };
}
