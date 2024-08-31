{
  home = {
    config,
    pkgs,
    env,
    myLib,
    lib,
    ...
  }: {
    home.packages = [pkgs.yarn];
    my.gc.yarn.script = ''rm -rf ~/.cache/yarn/*'';
  };
}
