{
  home = {
    config,
    pkgs,
    lib,
    env,
    myLib,
    user,
    ...
  }: {
    home.packages = [
    ];
  };
  os = {
    config,
    pkgs,
    env,
    myLib,
    user,
    ...
  }: let
    rawDerivations = {
    };
    winDerivations = builtins.mapAttrs (name: sourceDerivation:
      myLib.mkWinDerivation {
        inherit sourceDerivation;
        storeDir = env.winNixStore;
      })
    rawDerivations;
  in {
    wsl.enable = true;
    wsl.defaultUser = user;

    nixpkgs.overlays = [
      (final: prev: (builtins.mapAttrs (name: {derivation, ...}: derivation) winDerivations))
    ];
    system.activationScripts = builtins.mapAttrs (name: {activation, ...}: activation) winDerivations;
  };
}
