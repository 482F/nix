{
  home = {
    config,
    pkgs,
    env,
    myLib,
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
      pkgs.wget
      pkgs.unzip
      pkgs.ouch
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
        suntil = ''function suntil() { tsd start "sleep-until 15:00 && $@"; }; suntil'';
        ".." = "cd ..";
      };
      initExtra = ''
        bind '"\C-jj":"pushd +1 > /dev/null 2>&1 && pwd"'
        bind '"\C-jk":"pushd -0 > /dev/null 2>&1 && pwd"'
        bind '"\C-ja":"pushd . > /dev/null 2>&1 && pwd"'
        bind '"\C-jd":"pushd +1 > /dev/null 2>&1 && popd -0 -n > /dev/null 2>&1 && pwd"'
        bind '"\C-jl":"dirs -p -v"'
        bind -x '"\C-x\C-f":"fg"'
      '';
      historyFileSize = 10000000;
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
        home.packages = [
          pkgs.trash-cli
          (myLib.writeScriptBin "wmnt" ''
            uid="$(id -u)"
            gid="$(id -g)"
            drives="$(psh '(Get-PSDrive).Name') | grep -Po '^[A-Z](?=\r)' | perl -ne 'print lc'"

            echo "$drives" | xargs -I {} sudo mount -t drvfs {}:\\ /mnt/{} -o uid=$uid -o gid=$gid
          '')
        ];
        programs.bash = {
          shellAliases = {
            rm = "trash";
          };
        };
      }
    ];
  };
  os =
    # Edit this configuration file to define what should be installed on
    # your system. Help is available in the configuration.nix(5) man page, on
    # https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
    # NixOS-WSL specific options are documented on the NixOS-WSL repository:
    # https://github.com/nix-community/NixOS-WSL
    {
      config,
      lib,
      pkgs,
      env,
      ...
    } @ inputs: {
      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It's perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "23.11"; # Did you read the comment?

      time.timeZone = env.timeZone;

      nix = {
        settings = {
          experimental-features = ["nix-command" "flakes"];
        };
      };

      users.users = builtins.mapAttrs (name: hash: {hashedPassword = hash;}) env.passhashes;
      users.mutableUsers = false;
      security.pki.certificates = builtins.attrValues env.pki.certificates;
      security.sudo.wheelNeedsPassword = true;

      networking = {
        hostName = env.hostname;
        proxy = lib.mkIf ((env.proxy or null) != null) (
          let
            proxy = lib.strings.concatStrings ["http://" env.proxy.host ":" env.proxy.port];
          in {
            default = proxy;
            allProxy = proxy;
            noProxy = "localhost";
          }
        );
      };

      environment.etc.machine-id.source =
        (pkgs.runCommand "machine-id" {} ''
          ${pkgs.coreutils}/bin/mkdir -p $out
          ${pkgs.util-linux}/bin/uuidgen -r | ${pkgs.coreutils}/bin/tr -d - > $out/machine-id
        '')
        .out
        + /machine-id;
    };
}
