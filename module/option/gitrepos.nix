{
  home = {
    config,
    lib,
    pkgs,
    user,
    ...
  }: let
    inherit (lib) mkOption types;
    cfg = config.my.gitrepos;
  in {
    options = {
      my.gitrepos = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            dest = mkOption {type = types.path;};
            remote = mkOption {type = types.str;};
            finalRemote = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        });
      };
    };
    config.home.activation.my-git-repos = let
      repos = builtins.attrValues (lib.filterAttrs (name: {enable, ...}: enable) cfg);
      script = lib.concatMapStrings (args: let
        inherit (args) remote dest;
        finalRemote =
          if args.finalRemote == null
          then remote
          else args.finalRemote;
      in
        # bash
        ''
          function _() {
            if [[ -d '${dest}' ]]; then
              return 0
            fi
            NIX_SSL_CERT_FILE='/etc/ssl/certs/ca-certificates.crt' run nix shell nixpkgs#git nixpkgs#openssh --command git clone '${remote}' '${dest}'
            run cd '${dest}'
            run nix shell nixpkgs#git --command git remote set-url origin '${finalRemote}'
            run cd -
          }
          _; unset -f _
        '')
      repos;
    in
      config.lib.dag.entryAfter ["writeBoundary"] script;
  };
}
