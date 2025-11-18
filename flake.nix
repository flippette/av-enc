{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.writeShellScriptBin "nix-fmt" ''
          ${pkgs.alejandra}/bin/alejandra -q .
        '';

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
