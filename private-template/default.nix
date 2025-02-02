{myLib}: {
  env = {
    hostname = "nixos";
    username = "nixos";
    passhashes = {
      # mkpasswd -m sha-512
      nixos = "$6$KqQFPMIXN3hgNLoz$XT3uhwp8xZxhFBOBMNAH5fdgbyMFpp4dZYf1AucAexi33M4FPFVXLikdtg6T0PgME7EHYYQZZzhhy2CPS9rj7.";
    };

    timeZone = "Etc/UTC";
    proxy = null;
    _proxy = {
      host = "xxx.xxx.xxx.xxx";
      port = "xxxxx";
    };
    sshd = null;
    _sshd = {
      ports = [99999];
      authorizedKeys = {
        ishikawa-r = "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
      };
    };
    ssh.secretKeys.nixos = [
      "/path/str/to/id_rsa"
    ];
    pki.certificates = {
      sb = ''
        -----BEGIN CERTIFICATE-----
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        -----END CERTIFICATE-----
      '';
    };
    aws.credential = "/path/str/to/.aws/credentials";
    jdtls.formatterXml = null;
    _jdtls.formatterXml = "/path/str/to/jdtls/formatter.xml";
    checkstyle.configXml = null;
    winNixStore = "/mnt/c/nix/store";
  };
  optional = {
    wsl = true;
    # docker = true;
    # java = true;
    # sshd = true;
    # aws = true;
    # certbot = true;
    # nodejs = true;
    # python = true;
    # mp3 = true;
    # rust = true;
    # barrier = true;
  };
  modules = myLib.importAll ./module;
}
