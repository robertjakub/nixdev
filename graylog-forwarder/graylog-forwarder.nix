{
  lib,
  pkgs,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  openjdk17_headless,
  openjdk21_headless,
  systemd,
  nixosTests,
}:
{
  version,
  hash,
  maintainers,
  license,
}:
stdenv.mkDerivation rec {
  pname = "graylog-forwarder_${lib.versions.majorMinor version}";
  inherit version;

  src = fetchurl {
    url = "https://downloads.graylog.org/releases/cloud/forwarder/${version}/graylog-forwarder-${version}-bin.tar.gz";
    inherit hash;
  };

  dontBuild = true;

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [
    "--set-default"
    "JAVA_HOME"
    "${if (lib.versionAtLeast version "7.0") then openjdk21_headless else openjdk17_headless}"
    "--set JAVA_CMD $JAVA_HOME/bin/java"
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ systemd ]}"
  ];

  buildInputs = with pkgs; [
    nss
    libxcb
    expat
    glib
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r graylog-forwarder.jar $out
    install -m 0555 bin/graylog-forwarder $out/bin
    wrapProgram $out/bin/graylog-forwarder $makeWrapperArgs
  '';

  meta = with lib; {
    description = "The Graylog Forwarder is a standalone agent that sends log data to Graylog";
    homepage = "https://www.graylog.org/";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    inherit license;
    inherit maintainers;
    mainProgram = "graylogctl";
    platforms = platforms.linux;
  };
}
