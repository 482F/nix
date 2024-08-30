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
      pkgs.gsudo
      pkgs.win32yank
    ];
  };
  os = {
    config,
    pkgs,
    env,
    myLib,
    user,
    ...
  }: let
    rawDerivations = rec {
      gsudo = pkgs.stdenv.mkDerivation rec {
        pname = "gsudo.exe";
        version = "2.5.1";
        src = pkgs.fetchzip {
          url = "https://github.com/gerardog/gsudo/releases/download/v${version}/gsudo.portable.zip";
          sha256 = "1m0b9gybf9ijmlsiwjcacib7amqjppb40f9fqifn4h4h1i6l0vmz";
          stripRoot = false;
        };
        buildCommand = ''
          mkdir -p "$out/bin"
          dest="$out/bin/${pname}"
          cp -ai "$src/x64/gsudo.exe" "$dest"
          chmod 755 "$dest"
        '';
      };
      win32yank = pkgs.stdenv.mkDerivation rec {
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
      };
    };
    winDerivations = builtins.mapAttrs (name: sourceDerivation:
      myLib.mkWinDerivation {
        inherit sourceDerivation;
        storeDir = env.winNixStore;
      })
    rawDerivations;
  in {
    wsl.enable = true;
    wsl.defaultUser = user;

    nixpkgs.overlays = [
      (final: prev: (builtins.mapAttrs (name: {derivation, ...}: derivation) winDerivations))
    ];
    system.activationScripts = builtins.mapAttrs (name: {activation, ...}: activation) winDerivations;
  };
}
