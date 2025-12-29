{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ? import sources.nixpkgs {inherit system;},
}: let
  inherit (pkgs) lib;
in
  lib.fix (self: {
    packages = lib.fix (self: {
      default = self.anienc;

      anienc =
        pkgs.callPackage
        ./nix/anienc.nix
        {
          ffmpeg = pkgs.ffmpeg.override {
            svt-av1 = self.svt-av1-psyex;
          };
        };

      svt-av1-psyex =
        pkgs.callPackage
        ./nix/svt-av1-psyex.nix
        {};
    });

    overlays.default = _: _: {
      inherit
        (self.packages)
        anienc
        svt-av1-psyex
        ;
    };
  })
