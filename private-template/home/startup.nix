{
  home = {
    config,
    pkgs,
    env,
    ...
  }: {
    my.startup.script = ''
      touch ~/startupped
    '';
  };
}
