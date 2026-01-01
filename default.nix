{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ?
    import sources.nixpkgs {
      inherit system;
    },
}: let
  buildFfmpeg = {ffmpeg, ...}:
    ffmpeg.override {
      svt-av1 = svt-av1-psyex;
    };

  anienc =
    pkgs.callPackage
    ./nix/anienc.nix
    {ffmpeg = buildFfmpeg pkgs;};

  svt-av1-psyex =
    pkgs.callPackage
    ./nix/svt-av1-psyex.nix
    {};
in {
  inherit
    anienc
    svt-av1-psyex
    ;

  ffmpeg = buildFfmpeg pkgs;

  overlay = _: prev: {
    inherit
      anienc
      svt-av1-psyex
      ;

    ffmpeg = buildFfmpeg prev;
  };
}
