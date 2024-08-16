{
  home = {
    config,
    pkgs,
    env,
    ...
  }: {
    # lftp -u vsftpd-c localhost:55382
    home.packages = [pkgs.lftp];
  };
}
