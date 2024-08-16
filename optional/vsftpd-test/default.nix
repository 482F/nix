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
  os = {
    config,
    pkgs,
    env,
    ...
  }: {
    services.vsftpd = {
      enable = true;
      userlistEnable = true;
      localUsers = true;
      userlist = ["vsftpd-c"];
      localRoot = "/home/$USER/ftp";
      extraConfig = ''
        listen_port=55382
      '';
    };
    users.users.vsftpd-c = {
      isNormalUser = true;
      isSystemUser = false;
      home = "/home/vsftpd-c";
      password = "vsftpd-c";
    };
  };
}
