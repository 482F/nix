{
  config,
  lib,
  pkgs,
  user,
  ...
}: {
  options = {
    my.systemd.timer = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          description = lib.mkOption {type = lib.types.str;};
          onCalendar = lib.mkOption {type = lib.types.listOf lib.types.str;};
          script = lib.mkOption {type = lib.types.str;};
        };
      });
    };
  };

  config.systemd.user.timers =
    builtins.mapAttrs (name: value: {
      Install = {WantedBy = ["timers.target"];};
      Timer = {OnCalendar = value.onCalendar;};
    })
    config.my.systemd.timer;
  config.systemd.user.services =
    builtins.mapAttrs (name: value: {
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
    })
    config.my.systemd.timer;
}
