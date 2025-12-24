{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.git-hooks-nix.flakeModule
      ];

      perSystem = {pkgs, ...}: {
        pre-commit = {
          check.enable = true;
          settings.package = pkgs.prek;
          settings.hooks.alejandra.enable = true;
        };

        packages = rec {
          default = anienc;

          anienc =
            pkgs.callPackage
            ./nix/anienc.nix
            {
              ffmpeg = pkgs.ffmpeg.override {
                svt-av1 = svt-av1-psyex;
              };
            };

          svt-av1-psyex =
            pkgs.callPackage
            ./nix/svt-av1-psyex.nix
            {};
        };
      };
    };
}
