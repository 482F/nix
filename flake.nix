{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
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
    user = "nixos";
    private = import /home/${user}/nix-private;
    myLib = import ./lib {};
  in {
    nixosConfigurations = {
      "my-nixos" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = let
          importOptionals = type:
            with builtins;
              concatLists (attrValues (mapAttrs (
                  opt: state: let
                    path = assert pathExists ./optional/${opt}; ./optional/${opt}/${type};
                  in
                    if state && pathExists path
                    then myLib.importAll path
                    else []
                )
                private.optional));
          specialArgs = {
            inherit (private) env;
            inherit user myLib;
          };
          dep = [
            nixos-wsl.nixosModules.wsl
            home-manager.nixosModules.home-manager
          ];

          os =
            myLib.importAll ./os
            ++ importOptionals "os"
            ++ private.modules.os;
          home = map (m: args: {home-manager.users.${user} = m args;}) (
            myLib.importAll ./home
            ++ importOptionals "home"
            ++ private.modules.home
          );
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
