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
      my.pkgs = mkOption {
        default = {};
        type = types.attrsOf types.package;
      };
    };
  };
}
