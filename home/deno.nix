{
  config,
  pkgs,
  env,
  ...
}: {
  home.packages = [pkgs.deno];
  home.sessionVariables = {
    DENO_TLS_CA_STORE = "system";
  };
}
