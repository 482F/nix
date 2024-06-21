{
  config,
  pkgs,
  env,
  user,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "${user}";
  home.homeDirectory = "/home/${user}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.oath-toolkit

    (pkgs.stdenv.mkDerivation rec {
      pname = "win32yank";
      version = "0.1.1";
      src = pkgs.fetchzip {
        url = "https://github.com/equalsraf/win32yank/releases/download/v${version}/win32yank-x64.zip";
        sha256 = "0gclg5cpbq0qxnj8jfnxsrxyq5is1hka4ydwi4w8p18rqvaw8az2";
        stripRoot = false;
      };
      buildCommand = ''
        mkdir -p "$out/bin"
        dest="$out/bin/${pname}"
        cp -ai "$src/win32yank.exe" "$dest"
        chmod 755 "$dest"
      '';
    })
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nixos/etc/profile.d/hm-session-vars.sh
  #
  # home.sessionVariables = {
  # };

  programs.bash = {
    enable = true;
    shellAliases = {
      relogin = "exec \"\${SHELL}\" -l";
    };
    initExtra = ''
      bind '"\C-jj":"pushd +1 > /dev/null 2>&1 && pwd"'
      bind '"\C-jk":"pushd -0 > /dev/null 2>&1 && pwd"'
      bind '"\C-ja":"pushd . > /dev/null 2>&1 && pwd"'
      bind '"\C-jd":"pushd +1 > /dev/null 2>&1 && popd -0 -n > /dev/null 2>&1 && pwd"'
      bind '"\C-jl":"dirs -p -v"'
      bind -x '"\C-x\C-f":"fg"'

      export ACD_PORT=55812

      PATH_TO_ACD="/home/${user}/git/misc/acd.ts"
      alias acdts="''${PATH_TO_ACD}"
      function acd() {
        if [[ "''${1:-}" == "completions" ]]; then
          acdts "''${@:1}"
          return
        fi
        local result=$(acdts "''${@}")
        if [[ "''${result}" == "cd"* ]]; then
          source <(echo "''${result}")
        elif [[ "''${result}" != "" ]]; then
          echo "''${result}"
        fi
      }
      (nohup "''${PATH_TO_ACD}" --listen >/dev/null 2>&1 &)
      source <(acdts completions bash | perl -pe 's/_acd_complete alias/COMP_WORDS=\"\''${COMP_WORDS[@]}\" COMP_CWORD=\"\''${COMP_CWORD}\" _acd_complete alias/')
    '';
  };

  programs.readline = {
    enable = true;
    bindings = {
      "\\C-n" = "history-search-forward";
      "\\C-p" = "history-search-backward";
    };
    variables = {
      editing-mode = "vi";
      show-mode-in-prompt = "on";
      completion-ignore-case = "on";
      vi-ins-mode-string = "\\1\\e[34;1m\\2(ins) \\1\\e[0m\\2";
      vi-cmd-mode-string = "\\1\\e[31;1m\\2(cmd) \\1\\e[0m\\2";
    };
  };

  programs.gh = {
    enable = true;
  };

  xdg.enable = true;

  home.sessionVariables = {
    EDITOR = "rnvim --wait";
  };

  imports = [
    {
      programs.eza = {
        enable = true;
        git = true;
        extraOptions = [
          "--time-style=iso"
          "--group-directories-first"
        ];
      };
      programs.bash = {
        shellAliases = {
          ls = "eza";
          ll = "eza -l";
          lla = "eza -la";
        };
      };
    }
    {
      programs.bat = {
        enable = true;
        config = {
          theme = "OneHalfLight";
        };
      };
      programs.bash = {
        shellAliases = {
          cat = "bat";
        };
      };
    }
    {
      home.packages = [pkgs.trash-cli];
      programs.bash = {
        shellAliases = {
          rm = "trash";
        };
      };
    }
  ];
}
