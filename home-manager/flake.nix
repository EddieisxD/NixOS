rec {
  description = "Home Manager configuration of addy";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
  };

  outputs =
  { nixpkgs, home-manager, ... }@input:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {

    homeConfigurations."addy" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

    # Specify your home configuration modules here, for example,
    # the path to your home.nix.
      modules = [ ./home.nix ];

    # Optionally use extraSpecialArgs
    # to pass through arguments to home.nix
      extraSpecialArgs = {
        nix4nvchad = input.nix4nvchad;
        antigravity-nix = input.antigravity-nix;
        nix-flatpak = input.nix-flatpak;
      };
    };
  };
}
