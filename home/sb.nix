{
  config,
  pkgs,
  env,
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
}
