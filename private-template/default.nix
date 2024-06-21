{myLib}: {
  env = {
    hostname = "nixos";
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
  };
  optional = {
    wsl = true;
    docker = false;
    jdtls = false;
    sshd = false;
    aws = false;
    certbot = false;
  };
  modules = {
    home = myLib.importAll ./home;
    os = myLib.importAll ./os;
  };
}
