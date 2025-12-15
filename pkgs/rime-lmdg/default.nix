{
  lib,
  stdenvNoCC,
  fetchurl,
  unstableGitUpdater,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rime-lmdg";
  version = "lts-20251210-75240a90be8c3b";

  src = fetchurl {
    url = "https://github.com/jetcookies/RIME-LMDG-tracker/releases/download/${finalAttrs.version}/wanxiang-lts-zh-hans.gram";
    hash = "sha256-dSQKkL6MO9RvvktGtbh+Pn1EZrwb3GuaX+a0GsTEzjA=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/rime-data
    install -Dm755 $src $out/share/rime-data/wanxiang-lts-zh-hans.gram

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater {
    url = "github:jetcookies/RIME-LMDG-tracker";
    branch = "master";
    hardcodeZeroVersion = true;
  };

  meta = {
    description = "LMDG - Language, Model, Dictionary, Grammar";
    homepage = "https://github.com/amzxyz/RIME-LMDG";
    downloadPage = "https://github.com/amzxyz/RIME-LMDG/releases/tag/LTS";
    license = lib.licenses.cc-by-40;
    platforms = lib.platforms.all;
  };
})