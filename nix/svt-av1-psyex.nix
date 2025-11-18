{
  # nixpkgs
  lib,
  stdenv,
  fetchFromGitHub,
  # build deps
  cmake,
  cpuinfo,
  nasm,
  ...
}:
stdenv.mkDerivation {
  pname = "svt-av1-psyex";
  version = "3.0.2-B";

  src = fetchFromGitHub {
    owner = "blueswordm";
    repo = "svt-av1-psyex";
    rev = "3beb4aee471c686ecb05089b29b0e676026aea1b";
    hash = "sha256-klfrbow8UtpIPwIgt8tK7FP7Jp6In9nxfOZrdi1PsHo=";
  };

  nativeBuildInputs =
    [cmake]
    ++ lib.optionals
    stdenv.hostPlatform.isx86_64
    [nasm];

  buildInputs = [cpuinfo];

  cmakeFlags = [
    (lib.cmakeBool "SVT_AV1_LTO" true)
  ];

  meta = {
    homepage = "https://github.com/blueswordm/svt-av1-psyex";
    description = "Scalable Video Technology AV1 Encoder and Decoder";

    longDescription = ''
      The Scalable Video Technology for AV1 (SVT-AV1 Encoder and Decoder)
      with perceptual enhancements for psychovisually optimal AV1 encoding.
    '';

    license = [
      lib.licenses.aom
      lib.licenses.bsd3
    ];
    platforms = lib.platforms.unix;
    mainProgram = "SvtAv1EncApp";
  };
}
