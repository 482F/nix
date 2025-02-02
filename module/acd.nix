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
        export ACD_PORT=55812

        PATH_TO_ACD="${config.my.gitrepos.misc.dest}/acd.ts"
        alias acdts="$PATH_TO_ACD"
        function acd() {
          if [[ "''${1:-}" == "completions" ]]; then
            acdts "''${@:1}"
            return
          fi
          local result=$(acdts "$@")
          if [[ "$result" == "cd"* ]]; then
            source <(echo "$result")
          elif [[ "$result" != "" ]]; then
            echo "$result"
          fi
        }
        (nohup "$PATH_TO_ACD" --listen >/dev/null 2>&1 &)
        source <(acdts completions bash | perl -pe 's/_acd_complete alias/COMP_WORDS=\"\''${COMP_WORDS[@]}\" COMP_CWORD=\"\$COMP_CWORD\" _acd_complete alias/')
      '';
    };
    my.gitrepos = {
      misc = {
        remote = "https://github.com/482F/misc.git";
        finalRemote = "git@github.com:482F/misc.git";
        dest = "${config.home.homeDirectory}/git/misc";
      };
    };
  };
}
