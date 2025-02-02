{
  home = {
    config,
    pkgs,
    lib,
    env,
    user,
    myLib,
    ...
  }: let
    sb = myLib.writeScriptBinWithArgs "sb" "bash ${config.my.gitrepos.misc.dest}/sb.sh";
    scripts = {
      pyobj-to-json = "${config.my.gitrepos.misc.dest}/pyobj-to-json.ts";
      sleep-until = "${config.my.gitrepos.misc.dest}/sleep-until.ts";
      deno-build = "${config.my.gitrepos.misc.dest}/deno-build.ts";
      jwt = "${config.my.gitrepos.misc.dest}/jwt.ts";
      prepend-ps1 = "${config.my.gitrepos.misc.dest}/prepend-ps1.sh";
      tsd = "${config.my.gitrepos.tmux-start-daemon.dest}/main.ts";
    };
    derivations =
      {inherit sb;}
      // (builtins.mapAttrs (name: path: myLib.writeScriptBinWithArgs name "${config.my.pkgs.sb}/bin/sb ${path}") scripts);
  in {
    home.packages = builtins.attrValues derivations;
    my.pkgs = derivations;

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
