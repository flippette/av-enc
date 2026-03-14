{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages = {
      default = config.packages.anienc;

      anienc =
        pkgs.callPackage ../anienc.nix
        {inherit (config.packages) ffmpeg;};

      ffmpeg = pkgs.ffmpeg.override {
        svt-av1 = config.packages.svt-av1-psyex;
      };

      svt-av1-psyex =
        pkgs.callPackage ../svt-av1-psyex.nix {};
    };
  };
}
