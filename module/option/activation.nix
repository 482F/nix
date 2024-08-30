{
  home = {
    config,
    lib,
    pkgs,
    user,
    myLib,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption types;
  in {
    options = {
      my.activation = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            activate = mkOption {type = types.str;};
            cleanup = mkOption {type = types.str;};
          };
        });
      };
    };

    config.home.extraBuilderCommands = let
      my-activations = pkgs.symlinkJoin {
        name = "my-activations";
        paths = lib.pipe config.my.activation [
          (lib.filterAttrs (name: {enable, ...}: enable))
          (builtins.mapAttrs (name: {
            activate,
            cleanup,
            ...
          }: {inherit activate cleanup;}))
          (lib.mapAttrsToList (name: value:
              lib.mapAttrsToList (type: body: {inherit name type body;}) value))
          lib.lists.flatten
          (builtins.map (
            {
              name,
              type,
              body,
            }:
              pkgs.writeTextFile {
                name = "my-activation-${name}-${type}";
                text = ''
                  #!${pkgs.bash}/bin/bash --login
                  ${body}
                '';
                executable = true;
                destination = "/${name}/${type}";
              }
          ))
        ];
      };
    in ''
      ln -s ${my-activations} $out/my-activations
    '';
    config.home.activation.my-activation =
      config.lib.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        set -ue -o pipefail

        function main() {
          local old=$oldGenPath/my-activations
          local new=$newGenPath/my-activations
          local list="$({ ls -1 $old || true; ls -1 $new || true; } 2> /dev/null | sort | uniq)"
          echo $list > ~/act.log
          while read -u 10 name; do
            if diff -rq $old/$name $new/$name &> /dev/null; then
              continue
            fi
            echo has difference $name >> ~/act.log

            local cleanup=$old/$name/cleanup
            local activate=$new/$name/activate
            if [[ -e $cleanup ]]; then
              $cleanup || true
            fi
            if [[ -e $activate ]]; then
              $activate || true
            fi
          done 10<<< "$list"
        }
        main "$@"
        unset -f main
      '';
  };
}
