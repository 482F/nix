{
  config,
  pkgs,
  env,
  user,
  ...
}: {
  programs.awscli = {
    enable = true;
    settings = {
      default = {
        output = "json";
      };
    };
  };
  home.activation.aws-credentials =
    if (env.aws.credential or null) == null
    then ""
    else
      config.lib.dag.entryAfter ["writeBoundary"] ''
        run mkdir -p $HOME/.aws
        run cat "${env.aws.credential}" > $HOME/.aws/credentials
      '';
}
