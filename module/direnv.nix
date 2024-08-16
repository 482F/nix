{
  home = {
    config,
    pkgs,
    env,
    ...
  }: {
    programs = {
      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
