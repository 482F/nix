{
  config,
  pkgs,
  env,
  ...
}: {
  home.file."startup.sh".text = ''
    touch ~/startupped
  '';
}
