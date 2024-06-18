{
  config,
  pkgs,
  env,
  ...
}: {
  programs.bash = {
    enable = true;
    initExtra = ''
      source ${config.programs.git.package}/share/bash-completion/completions/git-prompt.sh
      PROMPT_COMMAND="__git_ps1 '\h:\W \u' '\\\$ ' 2>/dev/null; $PROMPT_COMMAND"
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
}
