{
  os = {
    config,
    pkgs,
    env,
    myLib,
    user,
    ...
  }: {
    virtualisation.docker = {
      enable = true;
    };
    users.groups.docker = {
      members = [user];
    };
  };
}
