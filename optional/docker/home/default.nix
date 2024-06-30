{
  config,
  pkgs,
  env,
  myLib,
  user,
  ...
}: {
  home.file.".docker/config.json".text =
    if env.proxy == null
    then null
    else ''
      {
        "proxies": {
          "default": {
            "httpProxy": "http://${env.proxy.host}:${env.proxy.port}",
            "httpsProxy": "http://${env.proxy.host}:${env.proxy.port}",
            "noProxy": "localhost;127.0.0.*"
          }
        }
      }
    '';
}
