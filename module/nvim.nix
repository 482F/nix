{
  home = {
    config,
    pkgs,
    env,
    user,
    myLib,
    ...
  }: {
    imports = [
      (myLib.gitClone {
        homeManagerLib = config.lib;
        cloneRemote = "https://github.com/482F/dotfiles.git";
        finalRemote = "git@github.com:482F/dotfiles.git";
        dist = "${config.home.homeDirectory}/git/dotfiles";
      })
    ];

    programs.neovim = {
      enable = true;
      extraLuaConfig =
        # lua
        ''
          vim.opt.rtp:prepend('${config.home.homeDirectory}/git/dotfiles/.config/nvim/')
          vim.cmd.luafile('${config.home.homeDirectory}/git/dotfiles/.config/nvim/init.lua')
        '';
    };

    home.packages = [
      (myLib.withRuntimeDeps {
        targetDerivation = config.programs.neovim.finalPackage;
        binName = "nvim";
        runtimeDepDerivations =
          (map myLib.lazyNixRun [
            # formatters
            "stylua"
            "alejandra"
            "prettierd"
            {
              binName = "autopep8";
              pkgName = "python312Packages.autopep8";
            }
            {
              binName = "pg_format";
              pkgName = "pgformatter";
            }

            # LSPs
            "lua-language-server"
          ])
          ++ [
            pkgs.gcc # for treesitter
            pkgs.ripgrep # for telescope
            pkgs.fd # for telescope
            (myLib.writeScriptBinWithArgs "vue-language-server" "deno run -A npm:@vue/language-server@latest")
            (myLib.writeScriptBinWithArgs "typescript-language-server" "deno run -A npm:typescript-language-server@latest")
            (myLib.writeScriptBinWithArgs "prettier" "deno run --allow-sys --allow-env --allow-read npm:prettier@latest")
          ];
      })

      (myLib.writeScriptBinWithArgs "rnvim" "sb ~/git/misc/rnvim.ts")
    ];

    programs.bash = {
      enable = true;
      shellAliases = {
        nv = "rnvim";
      };
    };

    # for skkeleton
    xdg.dataFile."nvim/skk/SKK-JISYO.L".text = builtins.readFile (pkgs.fetchurl {
      "url" = "https://github.com/skk-dev/dict/raw/090619ac57ef230a0506c191b569fc8c82b1025b/SKK-JISYO.L";
      "sha256" = "090gl7vmhvvcr4mw8ghx2wl03g2w86zf9x3c4730nnhqwi2zr5p8";
    });
  };
}
