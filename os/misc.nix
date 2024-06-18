# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  config,
  lib,
  pkgs,
  env,
  ...
} @ inputs: {
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  time.timeZone = env.timeZone;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };
  security.pki.certificates = builtins.attrValues env.pki.certificates;

  networking = {
    hostName = env.hostname;
    proxy = lib.mkIf (env.proxy != null) (
      let
        proxy = lib.strings.concatStrings ["http://" env.proxy.host ":" env.proxy.port];
      in {
        default = proxy;
        allProxy = proxy;
        noProxy = "localhost";
      }
    );
  };

  services.openssh = lib.mkIf (env.sshd != null) {
    enable = true;
    ports = env.sshd.ports;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  users.users.nixos.openssh.authorizedKeys.keys = builtins.attrValues env.sshd.authorizedKeys;
}
