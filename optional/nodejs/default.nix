{
  home = {
    config,
    pkgs,
    env,
    myLib,
    lib,
    ...
  }: {
    home.packages = [
      (pkgs.yarn.override {
        nodejs = pkgs.nodejs_22;
      })
    ];
    my.gc.yarn.script = ''rm -rf ~/.cache/yarn/*'';
  };
}
