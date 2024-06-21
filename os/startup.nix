{
  config,
  pkgs,
  env,
  user,
  ...
}: {
  systemd.user.services.win-startup = {
    wantedBy = ["default.target"];
    description = "startup for windows";
    script = ''
      startup="$HOME/startup.sh"
      if [[ ! -f "$startup" ]]; then
        exit 0
      fi
      . /etc/profile
      . "$startup"
    '';
  };
}
