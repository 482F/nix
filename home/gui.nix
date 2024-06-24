{
  config,
  pkgs,
  env,
  ...
}: {
  home.packages = map (n:
    pkgs.writeScriptBin n ''
      export NIXPKGS_ALLOW_UNFREE=1
      command="nix run --impure nixpkgs#${n} --"
      if [[ ''${FG:-} == 1 ]]; then
        $command "$@"
      else
        nohup $command "$@" > /dev/null 2>&1 &
      fi
    '') [
    "postman"
    "brave"
    "pgadmin"
    "slack"
  ];
}
