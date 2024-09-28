{
  home = {
    config,
    lib,
    pkgs,
    env,
    user,
    ...
  }: {
    programs.bash = {
      historySize = -1;
      historyFileSize = -1;
    };
    my.systemd.timer.bash-history-commit = {
      description = "git commit bash_history";
      onCalendar = ["*-*-* 15:00:00"];
      script = ''
        set -ue -o pipefail

        if [[ ! -f ~/.bash_history ]]; then
          exit 0
        fi

        bash_hist_dir=~/git/bash_history
        if [[ ! -d "$bash_hist_dir" ]]; then
          mkdir -p "$bash_hist_dir"
        fi

        cd "$bash_hist_dir"

        git="${pkgs.git.outPath}/bin/git"
        if [[ ! -d "$bash_hist_dir/.git" ]]; then
          "$git" init
        fi

        if [[ ! -f "$bash_hist_dir/.bash_history" ]]; then
          mv ~/.bash_history ./
          ln -s "$(pwd)/.bash_history" ~/.bash_history
        fi

        name=nix
        email=nix@example.com
        git add .; GIT_AUTHOR_NAME=$name GIT_AUTHOR_EMAIL=$email GIT_COMMITTER_NAME=$name GIT_COMMITTER_EMAIL=$email git commit -m "commit .bash_history"
      '';
    };
  };
}
