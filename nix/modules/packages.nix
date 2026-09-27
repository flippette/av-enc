{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages.default = config.packages.anienc;
    packages.anienc = pkgs.callPackage ../anienc.nix {};
  };
}
