{
  # nixpkgs
  lib,
  makeWrapper,
  stdenvNoCC,
  # build deps
  shellcheck,
  # runtime deps
  ab-av1,
  coreutils,
  ffmpeg,
  ripgrep,
  ...
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "anienc";
  version = "1.0.0";

  src = ../.;

  nativeBuildInputs = [
    makeWrapper
    shellcheck
  ];

  buildInputs = [
    ab-av1
    coreutils
    ffmpeg
    ripgrep
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
    path =
      lib.makeBinPath
      finalAttrs.buildInputs;
    inherit (finalAttrs) svtav1_preset;
  in ''
    wrapProgram $out/bin/anienc \
      --set PATH ${path} \
      --set svtav1_preset ${svtav1_preset}
  '';

  # default svt-av1 preset, see `/anienc` script
  svtav1_preset = "4";
})
