{
  lib,
  rustPlatform,
  buildNpmPackage,
  fetchFromGitHub,
  makeDesktopItem,

  cargo-tauri,
  pkg-config,

  atkmm,
  eudev,
  gdk-pixbuf,
  glib,
  gtk3,
  libgudev,
  libsoup_3,
  pango,
  pcsclite,
  webkitgtk_4_1,
}:
rustPlatform.buildRustPackage (finalAttrs: {

  pname = "picoforge";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "librekeys";
    repo = "picoforge";
    rev = "v${finalAttrs.version}";
    hash = "sha256-xc25LnDoIRwCT9QrTEAOiy0H7iVAL8DNCbLo2yhRwfQ=";
  };

  cargoRoot = "src-tauri";

  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoHash = "sha256-+2TKSA0otct5KYiSy5hP0ZH8WlhM/Wr8ibwMVE5pcpo=";

  npmDist = buildNpmPackage {
    name = "${finalAttrs.pname}-${finalAttrs.version}-dist";
    inherit (finalAttrs) src;

    patches = [ ./add-package-lock.patch ];

    npmDepsHash = "sha256-Jzsfpbo0/+iqnOlknlZi/SKbN6zQjrYByGCtabvRCKs=";

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r build/* $out

      runHook postInstall
    '';
  };

  patches = [ ./remove-tauri-beforeBuildCommand.patch ];

  postPatch = ''
    cp -r ${finalAttrs.npmDist} build
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    pkg-config
  ];

  buildInputs = [
    atkmm
    eudev
    gdk-pixbuf
    glib
    gtk3
    libgudev
    libsoup_3
    pango
    pcsclite
    webkitgtk_4_1
  ];

  postInstall = ''
    install -Dm644 ${finalAttrs.src}/static/pico-forge.svg $out/share/icons/hicolor/scalable/apps/picoforge.svg
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "picoforge";
      desktopName = "PicoForge";
      exec = "picoforge";
      terminal = false;
      icon = "picoforge";
      comment = finalAttrs.meta.description;
      categories = [ "Utility" ];
    })
  ];

  meta = {
    changelog = "https://github.com/librekeys/picoforge/releases/tag/v${finalAttrs.version}";
    description = "An open source commissioning tool for Pico FIDO security keys.";
    homepage = "https://github.com/librekeys/picoforge";
    license = lib.licenses.agpl3Only;
    mainProgram = "picoforge";
  };
})
