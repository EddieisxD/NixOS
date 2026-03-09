{
  description = "Pinning my NixOS configuration";
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url   = "github:nixos/nixpkgs/nixos-25.11";
    current.url  = "github:NixOS/nixpkgs?rev=0182a361324364ae3f436a63005877674cf45efb";
    nixpkgs.follows = "unstable";
  };
  outputs = { nixpkgs, ... }: 
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system; 
        modules = [
          ./configuration.nix
        ];
        specialArgs = {
          inherit nixpkgs;
        };
      };
    };
}
