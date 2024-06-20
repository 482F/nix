{
  config,
  pkgs,
  env,
  user,
  myLib,
  ...
}: {
  programs.neovim = {
    enable = true;
    extraLuaConfig = let
      HOME = "/home/${user}";
    in ''
      vim.opt.rtp:prepend('${HOME}/git/dotfiles/.config/nvim/')
      vim.cmd.luafile('${HOME}/git/dotfiles/.config/nvim/init.lua')
    '';
  };

  home.packages = [
    (myLib.withRuntimeDeps {
      targetDerivation = config.home-manager.users.nixos.programs.neovim.finalPackage;
      binName = "nvim";
      runtimeDepDerivations =
        (map myLib.lazyNixRun [
          # formatters
          "stylua"
          "alejandra"
          "prettierd"
          "prettier"

          # LSPs
          "lua-language-server"
          "typescript-language-server"
          "vue-language-server"
          "python-lsp-server"
        ])
        ++ [
          pkgs.gcc # for treesitter
          pkgs.ripgrep # for telescope
          pkgs.fd # for telescope
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
}
