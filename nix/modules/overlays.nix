{inputs, ...}: {
  imports = with inputs; [
    flake-parts.flakeModules.easyOverlay
  ];

  perSystem = {config, ...}: {
    overlayAttrs = {
      inherit (config.packages) anienc;
    };
  };
}
