{
  home = {
    config,
    pkgs,
    env,
    myLib,
    user,
    ...
  }: {
    home.file.".docker/config.json" = rec {
      enable = (env.proxy or null) != null;
      text =
        if enable
        then
          builtins.toJSON {
            proxies = {
              default = {
                httpProxy = "http://${env.proxy.host}:${env.proxy.port}";
                httpsProxy = "http://${env.proxy.host}:${env.proxy.port}";
                noProxy = "localhost;127.0.0.*";
              };
            };
          }
        else null;
    };
    my.gc.docker.script = ''
      ps="$(docker ps -q)"
      if [[ -n "$ps" ]]; then
        docker kill $ps
      fi
      docker system prune --volumes -a
    '';
  };
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
