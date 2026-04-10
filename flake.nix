{
  description = "Pinning my NixOS configuration";
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url   = "github:nixos/nixpkgs/nixos-25.11";
    current.url  = "github:NixOS/nixpkgs?rev=917fec990948658ef1ccd07cef2a1ef060786846";
    nixpkgs.follows = "unstable";
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
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
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
          inputs.disko.nixosModules.disko
          inputs.hjem.nixosModules.default
          ./disko/disko.nix
          ./configuration.nix
        ];
        specialArgs = {
          inherit inputs nixpkgs;
        };
      };
    };
}
