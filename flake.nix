{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    home-manager,
    ...
  }: let
    private = import /nix-private {inherit myLib;};
    user = private.env.username;
    myLib = import ./lib {};
  in {
    nixosConfigurations = {
      "my-nixos" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = let
          importedOptionals = with builtins;
            concatLists (nixpkgs.lib.mapAttrsToList (
                opt: state: let
                  path = assert pathExists ./optional/${opt}; ./optional/${opt};
                in
                  if state && pathExists path
                  then myLib.importAll path
                  else []
              )
              private.optional);
          specialArgs = {
            inherit (private) env;
            inherit user myLib;
          };
          dep =
            [
              home-manager.nixosModules.home-manager
            ]
            ++ (
              if private.optional.wsl
              then [nixos-wsl.nixosModules.wsl]
              else []
            );

          os =
            builtins.catAttrs "os"
            (myLib.importAll ./module
              ++ importedOptionals
              ++ private.modules);
          home =
            map (m: args: {
              home-manager.users.${user} = m (
                args // {config = args.config.home-manager.users.${user};}
              );
            }) (builtins.catAttrs "home" (
              myLib.importAll ./module
              ++ importedOptionals
              ++ private.modules
            ));
        in
          dep
          ++ map (
            m: ({
                config,
                lib,
                pkgs,
                ...
              } @ args:
                m (args // specialArgs))
          ) (os ++ home);
      };
    };
  };
}
