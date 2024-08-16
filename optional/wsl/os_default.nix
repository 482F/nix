{
  os = {
    config,
    pkgs,
    env,
    myLib,
    user,
    ...
  }: {
    wsl.enable = true;
    wsl.defaultUser = user;
  };
}
