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
      my.systemd.timer = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            description = mkOption {type = types.str;};
            onCalendar = mkOption {type = types.listOf types.str;};
            script = mkOption {type = types.str;};
          };
        });
      };
    };

    config.systemd.user.timers =
      builtins.mapAttrs (
        name: value: {
          Install = {WantedBy = ["timers.target"];};
          Timer = {OnCalendar = value.onCalendar;};
        }
      )
      (myLib.filterAttrs (name: value: value.enable) config.my.systemd.timer);
    config.systemd.user.services =
      builtins.mapAttrs (
        name: value: {
          Unit = {Description = value.description;};
          Service = {
            Type = "oneshot";
            ExecStart =
              (pkgs.writeScriptBin name (''
                  #!${pkgs.bash}/bin/bash --login
                ''
                + value.script))
              .outPath
              + "/bin/"
              + name;
          };
        }
      )
      (myLib.filterAttrs (name: value: value.enable) config.my.systemd.timer);
  };
}
