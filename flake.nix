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
      }: let
        ffmpeg = pkgs.ffmpeg_8-full.override {
          svt-av1 = pkgs.svt-av1-psy;
        };
      in {
        formatter = pkgs.writeShellScriptBin "nix-fmt" ''
          ${pkgs.alejandra}/bin/alejandra -q .
        '';

        packages = {
          default = self'.packages.anienc;

          anienc = pkgs.stdenvNoCC.mkDerivation rec {
            name = "anienc";
            src = ./.;

            nativeBuildInputs = [
              pkgs.shellcheck
              pkgs.makeWrapper
            ];

            buildInputs = [
              pkgs.ab-av1
              pkgs.ripgrep
              pkgs.uutils-coreutils-noprefix
              ffmpeg
            ];

            checkPhase = ''
              shellcheck ./anienc
            '';

            installPhase = ''
              install -Dm555 \
                ./anienc \
                $out/bin/anienc
            '';

            postFixup = let
              path = pkgs.lib.makeBinPath buildInputs;
            in ''
              wrapProgram $out/bin/anienc \
                --set PATH ${path}
            '';
          };
        };
      };
    };
}
