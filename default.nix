{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ?
    import sources.nixpkgs {
      inherit system;
    },
}: let
  packages = pkgs: rec {
    anienc =
      pkgs.callPackage
      ./nix/anienc.nix
      {inherit ffmpeg;};

    ffmpeg = pkgs.ffmpeg.override {
      svt-av1 = svt-av1-psyex;
    };

    svt-av1-psyex =
      pkgs.callPackage
      ./nix/svt-av1-psyex.nix
      {};
  };
in
  packages pkgs
  // {
    overlay = _: packages;
  }
