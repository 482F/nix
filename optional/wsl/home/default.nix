{
  config,
  pkgs,
  env,
  myLib,
  user,
  ...
}: {
  home.packages = with builtins;
    attrValues (mapAttrs myLib.writeScriptBinWithArgs {
      # TODO: $WINDIR を動的に取得したい
      psh = "/mnt/c/windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      wsl = "/mnt/c/windows/system32/wsl.exe";
      cmd = "/mnt/c/windows/system32/cmd.exe";
    })
    ++ [
      (pkgs.writeScriptBin "open" ''
        if [ $# != 1 ]; then
          explorer.exe .
        else
          if [ -e $1 ]; then
            cmd /c start $(wslpath -w $1) 2> /dev/null
          else
            echo "open: $1 : No such file or directory"
          fi
        fi
      '')
    ];

  programs.bash = {
    enable = true;
    profileExtra =
      # windows の PATH を wsl 側にも適用
      ''
        if [[ $PATH != *:/bin:* ]]; then
          export PATH="$PATH:/bin"
          function winpath() {
            local winpath="$(psh echo '$env:PATH')"
            local winpath_w="$(echo "''${winpath//\\/\/}" | grep -Po "[^;\r\n]+" | xargs -I {} wslpath -u {})"

            local path="$PATH"
            local filtereds="$(while read -u 10 line; do
              if [[ "$path" == *$line:* || "$path" == *$line ]]; then
                continue
              fi
              echo -n ":$line"
            done 10< <(echo "$winpath_w"))"
            echo "$path$filtereds"
          }

          export PATH="$(winpath)"
        fi
      '';
  };
}
