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

      suppress="/tmp/suppress-startup"
      if [[ -f "$suppress" ]]; then
        rm "$suppress"
        exit 0
      fi

      ${pkgs.bash.outPath}/bin/bash --login "$startup"

      while true; do sleep infinity; done
    '';
  };
}
