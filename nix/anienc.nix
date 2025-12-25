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
    svtav1_params = finalAttrs.env.svtav1_params;
  in ''
    wrapProgram $out/bin/anienc \
      --set PATH ${path} \
      --set svtav1_params ${svtav1_params}
  '';

  env.svtav1_params = "2";
})
