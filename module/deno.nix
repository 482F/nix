{
  home = {
    config,
    pkgs,
    env,
    ...
  }: {
    home.packages = [pkgs.deno];
    home.sessionVariables = {
      DENO_TLS_CA_STORE = "system";
    };
    my.gc.node.script = ''find ~/* -depth -path '**/node_modules/*' -delete'';
    my.gc.deno.script = ''rm -rf ~/.cache/deno/*'';
  };
}
