{
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
  ];
}
