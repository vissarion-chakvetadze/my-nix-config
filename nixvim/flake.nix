{
  description = "nixvim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, ... }:
  let
    system = "x86_64-linux";
    pkgs = (import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    }).extend (_: prev: {
      vimUtils = prev.vimUtils // {
        packDir = packages:
          let addPname = p: if p ? pname then p else p // { pname = p.name; };
          in prev.vimUtils.packDir (builtins.mapAttrs (_: pkg: {
            start = map addPname (pkg.start or []);
            opt = map addPname (pkg.opt or []);
          }) packages);
      };
    });
    nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit pkgs;
      module = import ./nixvim-module.nix;
    };
  in {
    packages.${system} = { inherit nvim; default = nvim; };
  };
}
