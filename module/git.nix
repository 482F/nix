{
  home = {
    config,
    pkgs,
    env,
    user,
    myLib,
    ...
  }: {
    programs.bash = {
      enable = true;
      initExtra = ''
        source ${config.programs.git.package}/share/bash-completion/completions/git-prompt.sh
        PROMPT_COMMAND="__git_ps1 '\h \u: \W' '\\\$ ' 2>/dev/null; $PROMPT_COMMAND"
        GIT_PS1_SHOWDIRTYSTATE=true
        GIT_PS1_SHOWSTASHSTATE=true
        GIT_PS1_SHOWUNTRACKEDFILES=true
        GIT_PS1_SHOWUPSTREAM="auto"
        GIT_PS1_SHOWCOLORHINTS=true
      '';
    };
    programs.git = {
      enable = true;
      includes = [
        {path = "~/git/dotfiles/.git-aliases";}
        {path = "~/git/dotfiles/.gitconfig";}
      ];
    };
    home.packages = [
      (myLib.withRuntimeDeps {
        targetDerivation = config.programs.git.package;
        binName = "git";
        runtimeDepPaths = ["${config.home.homeDirectory}/git/misc/git-commands"];
      })
    ];

    my.gitrepos = [
      {
        remote = "https://github.com/482F/dotfiles.git";
        finalRemote = "git@github.com:482F/dotfiles.git";
        dist = "${config.home.homeDirectory}/git/dotfiles";
      }
    ];
  };
}
