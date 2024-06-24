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
    myLib = import ./lib {};
    private = import /home/${user}/nix-private {inherit myLib;};
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
            myLib.importAll ./os
            ++ importOptionals "os"
            ++ private.modules.os;
          home =
            map (m: args: {
              home-manager.users.${user} = m (
                args // {config = args.config.home-manager.users.${user};}
              );
            }) (
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
