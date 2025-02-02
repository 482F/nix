{
  home = {
    config,
    pkgs,
    lib,
    env,
    myLib,
    user,
    ...
  }: {
    home.packages = [
      config.my.pkgs.psh
      config.my.pkgs.wsl
      config.my.pkgs.cmd
      (myLib.writeScriptBin "open" ''
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
      (myLib.writeScriptBin "lock" ''rundll32.exe user32.dll,LockWorkStation'')
    ];

    programs.bash = {
      enable = true;
      shellAliases = myLib.aliasEvalFn "reboot" ''
        distro="''${1:-}"
        if [[ -z "$distro" ]]; then
          echo argument is required >&2
          return 1
        fi

        touch /tmp/suppress-startup

        history -a

        ${config.my.pkgs.psh}/bin/psh Start-Process -WindowStyle Hidden -FilePath powershell -ArgumentList "\"
          wsl --terminate "$distro"
          for (\`\$i=0; \`\$i -lt 10; \`\$i++) {
            sleep 1
            wsl -d "nixos" echo boot "$distro"
          }
        \""
      '';
      profileExtra =
        # windows の PATH を wsl 側にも適用
        ''
          if [[ $PATH != *:/bin:* ]]; then
            export PATH="$PATH:/bin"
          fi

          function winpath() {
            local winpath="$(${config.my.pkgs.psh}/bin/psh echo '$env:PATH')"
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
        ''
        # windows の特定の変数を bash 側で使用できるように
        + (let
          winEnvs = [
            "APPDATA"
            "USERPROFILE"
            "LOCALAPPDATA"
            "WINDIR"
          ];
        in ''
          function set_winenv() {
            while read -u 10 entry; do
              local name="$(echo "$entry" | grep -Po "^[^:]+")"
              local value="$(echo "$entry" | grep -Po ".:[^:]+$")"
              local value_w="$(wslpath -u "$value")"
              export "$name=$value_w"
            done 10< <(${config.my.pkgs.psh}/bin/psh '${builtins.concatStringsSep "\n" (map (e: "echo ${e}:$env:${e}") winEnvs)}' | grep -Po "[^;\r]+" | sed 's/\\/\\\\/g')
          }
          set_winenv
        '');
    };
    my.pkgs = let
      win-runnables = {
        # TODO: $WINDIR を動的に取得したい
        wsl = "/mnt/c/windows/system32/wsl.exe";
        cmd = "/mnt/c/windows/system32/cmd.exe";
        psh = "/mnt/c/windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      };
      derivations = builtins.mapAttrs (name: path:
        pkgs.runCommand name {} ''
          mkdir -p $out/bin
          ln -s ${path} $out/bin/${name}
        '')
      win-runnables;
    in
      derivations;
  };
  os = {
    config,
    pkgs,
    env,
    myLib,
    user,
    ...
  }: {
    wsl.enable = true;
    wsl.defaultUser = user;
  };
}
