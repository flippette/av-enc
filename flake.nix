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
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        self',
        pkgs,
        ...
      }: {
        formatter = pkgs.writeShellScriptBin "nix-fmt" ''
          ${pkgs.alejandra}/bin/alejandra -q .
        '';

        packages = {
          default = self'.packages.anienc;

          anienc = pkgs.stdenvNoCC.mkDerivation {
            name = "anienc";
            src = ./.;

            nativeBuildInputs = [
              pkgs.shellcheck
            ];

            buildInputs = [
              pkgs.ab-av1
              pkgs.ffmpeg
            ];

            checkPhase = ''
              shellcheck ./anienc
            '';

            installPhase = ''
              install -Dm555 ./anienc $out/anienc
            '';
          };
        };
      };
    };
}
