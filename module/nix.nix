{
  home = {
    config,
    pkgs,
    lib,
    env,
    myLib,
    ...
  }: {
    nix.ext-subcommands = {
      enable = true;
    };
    my.gc.nix.script = ''
      sudo nix store gc
      ${pkgs.home-manager}/bin/home-manager expire-generations 0
      sudo nix-collect-garbage --delete-old
      nix-collect-garbage --delete-old
    '';
  };
}
