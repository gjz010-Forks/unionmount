{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    hfsnotify.url = "github:gjz010-Forks/hfsnotify";
    hfsnotify.flake = false;
  };
  outputs = inputs@{ nixpkgs, flake-parts, hfsnotify, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { config, self', pkgs, ... }: {
        haskellProjects.default = {
          autoWire = [ "packages" "apps" "checks" ]; # Wire all but the devShell
          packages = {
            fsnotify.source = inputs.hfsnotify;
          };
        };

        treefmt.config = {
          projectRootFile = "flake.nix";
          package = pkgs.treefmt;

          programs.ormolu.enable = true;
          programs.nixpkgs-fmt.enable = true;
          programs.cabal-fmt.enable = true;

          # We use fourmolu
          settings.formatter.ormolu = {
            options = [
              "--ghc-opt"
              "-XImportQualifiedPost"
            ];
          };
        };

        packages.default = self'.packages.unionmount;

        devShells.default = pkgs.mkShell {
          name = "unionmount";
          meta.description = "unionmount development environment";
          # See https://community.flake.parts/haskell-flake/devshell#composing-devshells
          inputsFrom = [
            config.haskellProjects.default.outputs.devShell
            config.treefmt.build.devShell
          ];
          packages = with pkgs; [
            just
          ];
        };
      };
    };
}
