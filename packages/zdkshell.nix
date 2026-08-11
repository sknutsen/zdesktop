{
  stdenvNoCC,
  lib,
  writeShellApplication,
  quickshell,
}: let
  zdkshellConfig = stdenvNoCC.mkDerivation {
    pname = "zdkshell-config";
    version = "0.1.0";
    src = ../shell;
    installPhase = ''
      mkdir -p $out/share/zdkshell
      cp -r . $out/share/zdkshell
    '';
  };
in {
  config = zdkshellConfig;

  default = writeShellApplication {
    name = "zdkshell";
    runtimeInputs = [quickshell];
    text = ''
      exec quickshell --path ${zdkshellConfig}/share/zdkshell "$@"
    '';
  };
}
