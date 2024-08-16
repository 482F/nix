{
  home = {
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

    programs.bash =
      if (env.ssh.secretKeys.${user} or null) == null
      then {}
      else {
        enable = true;
        initExtra = ''
          function ssh-add-if-necessary() {
            while read -u 10 _keyfile; do
              local keyfile="''${_keyfile// /}"
              local pub="$(ssh-keygen -l -f "$keyfile" | grep -Po "^\S+\s\S+")"
              # skip if already exists
              if (ssh-add -l 2>/dev/null || true) | grep -q "$pub"; then
                continue
              fi
              ssh-add "$keyfile"
            done 10<< "  END"
              ${builtins.concatStringsSep "\n" (env.ssh.secretKeys.${user} or [])}
            END
          }
          ssh-add-if-necessary
          unset -f ssh-add-if-necessary
        '';
      };
  };
}
