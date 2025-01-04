{
  home = {
    config,
    pkgs,
    env,
    user,
    system,
    myLib,
    ...
  }: let
    awsas = myLib.flakeToDerivation {
      local = "${config.my.gitrepos.misc.dest}/awsas";
      remote = "git+https://github.com/482F/misc?dir=awsas";
      inherit system;
    };
  in {
    home.packages = [
      pkgs.ssm-session-manager-plugin
      awsas
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
