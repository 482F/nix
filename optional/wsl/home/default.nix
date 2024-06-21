{
  config,
  pkgs,
  env,
  myLib,
  user,
  ...
}: {
  programs.bash = {
    enable = true;
    shellAliases = {
      psh = "powershell.exe";
    };
    initExtra = ''
      if [[ $PATH != *:/bin:* ]]; then
        export PATH="$PATH:/bin"
        function winpath() {
          local psh="/mnt/c/windows/System32/WindowsPowerShell/v1.0/powershell.exe"
          local winpath="$("$psh" echo '$env:PATH')"
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
