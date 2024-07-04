{
  config,
  lib,
  pkgs,
  env,
  user,
  ...
}: {
  services.openssh = lib.mkIf (env.sshd != null) {
    enable = true;
    ports = env.sshd.ports;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  users.users.${user}.openssh.authorizedKeys.keys = builtins.attrValues env.sshd.authorizedKeys;
}
