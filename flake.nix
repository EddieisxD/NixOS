{
  description = "Pinning my NixOS configuration";
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url   = "github:nixos/nixpkgs/nixos-25.11";
    current.url  = "github:NixOS/nixpkgs?rev=0182a361324364ae3f436a63005877674cf45efb";
    nixpkgs.follows = "current";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    stylix.url = "github:danth/stylix";
    vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };
  outputs = { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.home-manager.nixosModules.home-manager
          inputs.nix-index-database.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.disko.nixosModules.disko
          ./disko/disko.nix
          ./configuration.nix
        ];
        specialArgs = {
          inherit inputs nixpkgs;
        };
      };
    };
}
