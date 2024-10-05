{
  home = {
    config,
    pkgs,
    lib,
    env,
    user,
    myLib,
    ...
  }: {
    home.packages =
      [
        (myLib.writeScriptBinWithArgs "sb" "bash ~/git/misc/sb.sh")
      ]
      ++ (lib.mapAttrsToList (
          name: path: myLib.writeScriptBinWithArgs name "sb ${path}"
        ) {
          pyobj-to-json = "~/git/misc/pyobj-to-json.ts";
          sleep-until = "~/git/misc/sleep-until.ts";
          deno-build = "~/git/misc/deno-build.ts";
          tsd = "~/git/tmux-start-daemon/main.ts";
          jwt = "~/git/misc/jwt.ts";
        });

    my.gitrepos = {
      tmux-start-daemon = {
        remote = "https://github.com/482F/tmux-start-daemon.git";
        finalRemote = "git@github.com:482F/tmux-start-daemon.git";
        dist = "${config.home.homeDirectory}/git/tmux-start-daemon";
      };
      misc = {
        remote = "https://github.com/482F/misc.git";
        finalRemote = "git@github.com:482F/misc.git";
        dist = "${config.home.homeDirectory}/git/misc";
      };
    };
  };
}
