{
  config,
  pkgs,
  env,
  myLib,
  lib,
  ...
}: {
  home.packages =
    map (
      {
        suffix,
        nodeVersion,
        nodeSha256,
      }: let
        buildNodejs = pkgs.callPackage <nixpkgs/pkgs/development/web/nodejs/nodejs.nix> {python = pkgs.python310;};
        nodejs = buildNodejs {
          version = nodeVersion;
          sha256 = nodeSha256;
        };
        yarn = pkgs.yarn.override {
          inherit nodejs;
        };
      in
        myLib.writeScriptBinWithArgs "yarn${suffix}" "${yarn}/bin/yarn"
    ) [
      {
        suffix = "16";
        nodeVersion = "16.20.2";
        nodeSha256 = "sha256-V28aA8RV5JGo0TK1h+trO4RlH8iXS7NjhDPdRNIsj0k=";
      }
    ];
}
