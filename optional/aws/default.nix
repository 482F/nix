{
  home = {
    config,
    pkgs,
    env,
    user,
    ...
  }: {
    home.packages = [
      pkgs.ssm-session-manager-plugin
    ];
    programs.awscli = {
      enable = true;
      settings = {
        default = {
          output = "json";
          region = "ap-northeast-1";
        };
      };
    };
    home.file.".aws/credentials".source = config.lib.file.mkOutOfStoreSymlink env.aws.credential;
  };
}
