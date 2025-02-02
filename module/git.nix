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
        if [[ "$PS1" != *'__git_ps1'* ]]; then
          PS1='\h \u: \W$(__git_ps1 " (%s)")\$ '
        fi
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
        {path = "${config.my.gitrepos.dotfiles.dest}/.git-aliases";}
        {path = "${config.my.gitrepos.dotfiles.dest}/.gitconfig";}
      ];
    };
    home.packages = [
      (myLib.withRuntimeDeps {
        targetDerivation = config.programs.git.package;
        binName = "git";
        runtimeDepPaths = ["${config.home.homeDirectory}/git/misc/git-commands"];
      })
    ];

    my.gitrepos = {
      dotfiles = {
        remote = "https://github.com/482F/dotfiles.git";
        finalRemote = "git@github.com:482F/dotfiles.git";
        dest = "${config.home.homeDirectory}/git/dotfiles";
      };
    };
  };
  os = {...}: {
    programs.bash.promptInit = "";
  };
}
