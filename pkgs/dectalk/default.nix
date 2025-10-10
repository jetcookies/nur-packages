{
  lib,
  stdenvNoCC,
  fetchgit,
  makeDesktopItem,

  autoreconfHook,
  pkg-config,
  gcc13,
  unzip,
  git,

  alsa-lib,
  libpulseaudio,
  gtk2,
}:
stdenvNoCC.mkDerivation (finalAttrs: {

  pname = "dectalk";
  version = "2023-10-30";

  src = fetchgit {
    url = "https://github.com/dectalk/dectalk.git";
    tag = "${finalAttrs.version}";
    leaveDotGit = true;
    hash = "sha256-QM1tdDFxX9AaxJ0AB/oZWQqjQ0FIacdX8EqOmwlLihw=";
  };

  patches = [
    ./fix-bin.patch
    ./fix-fhs.patch
  ];


  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    gcc13 # https://github.com/dectalk/dectalk/commit/e7e967e3a8cbba7cf913a955e4dbcf55bf092aed
    unzip
    git
  ];

  buildInputs = [
    alsa-lib
    libpulseaudio
    gtk2
  ];

  preAutoreconf = ''
    cd src
  '';

  buildPhase = ''
    make -j release
  '';

  installPhase = ''
    runHook preInstall

    make -j install

    mkdir -p $out/share/pixmaps
    install -m 0644 $out/share/bitmaps/dtk.xpm $out/share/pixmaps/dtk.xpm
    install -m 0644 $out/share/bitmaps/pau16a.xpm $out/share/pixmaps/pau16a.xpm

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "gspeak";
      desktopName = "GSpeak";
      exec = "gspeak %U";
      terminal = false;
      icon = "pau16a";
      comment = "Speaking Text Editor";
      categories = [ "Utility" ];
    })
    (makeDesktopItem {
      name = "windic";
      desktopName = "Windic";
      exec = "windic %U";
      terminal = false;
      icon = "dtk";
      comment = "Windowed Dictionary Complier";
      categories = [ "Utility" ];
    })
  ];

  meta = {
    changelog = "https://github.com/dectalk/dectalk/releases/tag/${finalAttrs.version}";
    description = "Modern builds for the 90s/00s DECtalk text-to-speech application.";
    homepage = "https://github.com/dectalk/dectalk";
    license = lib.licenses.unfree;
    mainProgram = "gspeak";
  };
})
