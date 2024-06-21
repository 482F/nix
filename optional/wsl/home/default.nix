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
    });

  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $PATH != *:/bin:* ]]; then
        export PATH="$PATH:/bin"
        function winpath() {
          local winpath="$(psh echo '$env:PATH')"
          local winpath_w="$(echo "''${winpath//\\/\/}" | grep -Po "[^;\r\n]+" | xargs -I {} wslpath -u {})"

          local path="$PATH"
          local filtereds="$(echo "$winpath_w" | while read line; do
            if [[ "$path" == *$line:* || "$path" == *$line ]]; then
              continue
            fi
            echo -n ":$line"
          done)"
          echo "$path$filtereds"
        }

        export PATH="$(winpath)"
      fi
    '';
  };
}
