{
  home = {
    config,
    lib,
    pkgs,
    user,
    ...
  }: let
    inherit (lib) mkOption types;
  in {
    options = {
      my.startup = mkOption {
        default = {};
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            script = mkOption {
              type = types.lines;
              default = "";
            };
          };
        };
      };
    };

    imports = let
      enable = config.my.startup.enable && (config.my.startup.script != "");
    in [
      {
        config.home.file."startup.sh" =
          if enable
          then {
            executable = true;
            text = config.my.startup.script;
          }
          else {};

        config.systemd.user.services =
          if enable
          then {
            execute-startup = {
              Unit = {Description = "execute startup script";};
              Install = {WantedBy = ["default.target"];};
              Service = {
                Type = "oneshot";
                ExecStart =
                  (
                    pkgs.writeScriptBin "startup" ''
                      #!${pkgs.bash}/bin/bash

                      startup="$HOME/startup.sh"
                      if [[ ! -f "$startup" ]]; then
                        exit 0
                      fi

                      suppress="/tmp/suppress-startup"
                      if [[ -f "$suppress" ]]; then
                        ${pkgs.coreutils}/bin/rm "$suppress"
                        exit 0
                      fi

                      ${pkgs.bash.outPath}/bin/bash --login "$startup"

                      while true; do ${pkgs.coreutils}/bin/sleep infinity; done
                    ''
                  )
                  .outPath
                  + "/bin/startup";
              };
            };
          }
          else {};
      }
    ];
  };
}
