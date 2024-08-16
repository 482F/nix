{
  home = {
    config,
    pkgs,
    env,
    ...
  }: {
    home.packages = with pkgs; [
      rustc
      rust-analyzer
      rustfmt
      cargo
    ];

    home.sessionVariables = {
      RUST_SRC_PATH = pkgs.rust.packages.stable.rustPlatform.rustLibSrc;
    };

    my.gc.rust.script = ''rm -rf ~/.cargo/*'';
  };
}
