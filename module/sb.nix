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
        (myLib.writeScriptBinWithArgs "sb" "bash ${config.my.gitrepos.misc.dest}/sb.sh")
      ]
      ++ (lib.mapAttrsToList (
          name: path: myLib.writeScriptBinWithArgs name "sb ${path}"
        ) {
          pyobj-to-json = "${config.my.gitrepos.misc.dest}/pyobj-to-json.ts";
          sleep-until = "${config.my.gitrepos.misc.dest}/sleep-until.ts";
          deno-build = "${config.my.gitrepos.misc.dest}/deno-build.ts";
          jwt = "${config.my.gitrepos.misc.dest}/jwt.ts";
          tsd = "${config.my.gitrepos.tmux-start-daemon.dest}/main.ts";
        });

    my.gitrepos = {
      tmux-start-daemon = {
        remote = "https://github.com/482F/tmux-start-daemon.git";
        finalRemote = "git@github.com:482F/tmux-start-daemon.git";
        dest = "${config.home.homeDirectory}/git/tmux-start-daemon";
      };
      misc = {
        remote = "https://github.com/482F/misc.git";
        finalRemote = "git@github.com:482F/misc.git";
        dest = "${config.home.homeDirectory}/git/misc";
      };
    };
  };
}
