{
  config,
  pkgs,
  env,
  user,
  myLib,
  ...
}: {
  home.packages =
    [
      (myLib.writeScriptBinWithArgs "sb" "bash ~/git/misc/sb.sh")
    ]
    ++ (map ({
        name,
        path,
      }:
        myLib.writeScriptBinWithArgs name "sb ${path}")
      [
        {
          name = "git-zrb";
          path = "~/git/misc/git-commands/git-zrb";
        }
        {
          name = "git-zco";
          path = "~/git/misc/git-commands/git-zco";
        }
        {
          name = "git-chh";
          path = "~/git/misc/git-commands/git-chh";
        }
        {
          name = "git-dH";
          path = "~/git/misc/git-commands/git-dH";
        }
        {
          name = "git-init-push";
          path = "~/git/misc/git-commands/git-init-push";
        }
        {
          name = "pyobj-to-json";
          path = "~/git/misc/pyobj-to-json.ts";
        }
        {
          name = "sleep-until";
          path = "~/git/misc/sleep-until.ts";
        }
        {
          name = "tsd";
          path = "~/git/tmux-start-daemon/main.ts";
        }
      ]);

  imports = [
    (myLib.gitClone {
      homeManagerLib = config.lib;
      cloneRemote = "https://github.com/482F/tmux-start-daemon.git";
      finalRemote = "git@github.com:482F/tmux-start-daemon.git";
      dist = "${config.home.homeDirectory}/git/tmux-start-daemon";
    })
    (myLib.gitClone {
      homeManagerLib = config.lib;
      cloneRemote = "https://github.com/482F/misc.git";
      finalRemote = "git@github.com:482F/misc.git";
      dist = "${config.home.homeDirectory}/git/misc";
    })
  ];
}
