{
  home = {
    config,
    pkgs,
    env,
    myLib,
    ...
  }: {
    home.packages = [
      pkgs.mp3gain
      (myLib.writeScriptBinWithArgs "set-mp3-gain-value" ''sb ~/git/misc/set-mp3-gain-value.sh'')
      (myLib.writeScriptBinWithArgs "id3-writer" ''~/git/misc/id3-writer'')
      (
        let
          version = "2024.8.6";
          hash = "sha256-6FUfJryL9nuZwSNzzIftIHNDbDQ35TKQh40PS0ux9mM=";
          yt-dlp = pkgs.yt-dlp.overrideAttrs (attrs: rec {
            inherit version;
            name = "${attrs.pname}-${version}";
            src = pkgs.python3Packages.fetchPypi {
              inherit version hash;
              pname = "yt_dlp";
            };
          });
        in
          pkgs.writeScriptBin "yt-dlp-mp3" ''
            ${yt-dlp}/bin/yt-dlp --add-header Accept-Language:ja-JP --embed-metadata --retries 50 --ignore-errors --extract-audio --audio-format mp3 -a "$1"
            set-mp3-gain-value 75 .
          ''
      )
    ];
  };
}
