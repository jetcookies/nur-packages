{
  lib,
  stdenvNoCC,
  fetchFromGitHub,

  cmake,
  gcc-arm-embedded,
  picotool,
  python3,

  pico-sdk,

  # Options
  # https://github.com/polhenarejos/pico-fido#build-for-raspberry-pico
  picoboard ? "pico",
  vidpid ? null,
  usbvid ? null,
  usbpid ? null,
}:
assert lib.assertMsg (!(vidpid != null && (usbvid != null || usbpid != null))) "pico-fido: arguments 'vidpid' and 'usbvid/usbpid' are mutually exclusive.";
stdenvNoCC.mkDerivation (finalAttrs: {

  pname = "pico-fido";
  version = "7.2";

  src = fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-fido";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PKuIFfyIULlq9xSjcYtMTVm+r+5JjIJTtscxvlCxKdE=";
    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gcc-arm-embedded
    picotool
    python3
  ];

  PICO_SDK_PATH="${pico-sdk.override { withSubmodules = true; }}/lib/pico-sdk/";

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=${lib.getExe' gcc-arm-embedded "arm-none-eabi-gcc"}"
    "-DCMAKE_CXX_COMPILER=${lib.getExe' gcc-arm-embedded "arm-none-eabi-g++"}"
  ]
  ++ lib.optionals (picoboard != null) [ "-DPICO_BOARD=${picoboard}" ]
  ++ lib.optionals (vidpid != null) [ "-DVIDPID=${vidpid}" ]
  ++ lib.optionals (usbvid != null && usbpid != null) [ "-DUSB_VID=${usbvid}" "-DUSB_PID=${usbpid}" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/pico-fido
    install pico_fido.uf2 $out/share/pico-fido/pico_fido_${picoboard}-${finalAttrs.version}.uf2

    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/polhenarejos/pico-fido/releases/tag/v${finalAttrs.version}";
    description = "FIDO Passkey for Raspberry Pico and ESP32";
    homepage = "https://github.com/polhenarejos/pico-fido";
    license = lib.licenses.agpl3Only;
  };
})
