{
  config,
  pkgs,
  env,
  user,
  ...
}: {
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      function ssh-add-if-necessary() {
        while read _keyfile; do
          local keyfile="''${_keyfile// /}"
          local pub="$(ssh-keygen -l -f "$keyfile" | grep -Po "^\S+\s\S+")"
          # skip if already exists
          if ssh-add -l | grep -q "$pub"; then
            continue
          fi
          ssh-add "$keyfile"
        done << "  END"
          ${builtins.concatStringsSep "\n" env.ssh.secretKeys.${user}}
        END
      }
      ssh-add-if-necessary
      unset -f ssh-add-if-necessary
    '';
  };
}
