{
  os = {pkgs, ...}: {
    fonts = {
      packages = with pkgs; [
        noto-fonts-cjk-serif
        noto-fonts-cjk-sans
        noto-fonts-emoji
        (pkgs.stdenv.mkDerivation rec {
          pname = "Cica";
          version = "5.0.3";
          src = pkgs.fetchzip {
            url = "https://github.com/miiton/Cica/releases/download/v${version}/Cica_v${version}.zip";
            sha256 = "08yr7accwih7k37z8d19rfg8ha3j7illl5npy92d63wzc1yygl06";
            stripRoot = false;
          };
          buildCommand = ''
            dest=$out/share/fonts/truetype/
            mkdir -p $dest
            cp -ai $src/*.ttf $dest
          '';
        })
      ];
      fontDir.enable = true;
      fontconfig = {
        defaultFonts = {
          serif = ["Noto Serif CJK JP" "Noto Color Emoji"];
          sansSerif = ["Noto Sans CJK JP" "Noto Color Emoji"];
          monospace = ["Cica" "Noto Color Emoji"];
          emoji = ["Cica" "Noto Color Emoji"];
        };
      };
    };
  };
}
