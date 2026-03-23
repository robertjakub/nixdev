{
  lib,
  # pkgs,
  stdenv,
  fetchurl,
  makeWrapper,
  openjdk21_headless,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "graylog-forwarder_${lib.versions.majorMinor finalAttrs.version}";
  version = "7.1";

  src = fetchurl {
    url = "https://downloads.graylog.org/releases/cloud/forwarder/${finalAttrs.version}/graylog-forwarder-${finalAttrs.version}-bin.tar.gz";
    hash = "sha256-jOZIu/+/jAa7JDyMQgDbE17ueANKoMkOwMmVZ9aSoMk=";
  };

  dontBuild = true;
  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [
    "--set-default"
    "JAVA_HOME"
    "${openjdk21_headless}"
    "--set JAVA_CMD $JAVA_HOME/bin/java"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r graylog-forwarder.jar $out
    install -m 0555 bin/graylog-forwarder $out/bin
    wrapProgram $out/bin/graylog-forwarder $makeWrapperArgs
  '';

  meta = {
    description = "The Graylog Forwarder is a standalone agent that sends log data to Graylog";
    homepage = "https://www.graylog.org/";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    maintainers = with lib.maintainers; [ robertjakub ];
    license = lib.licenses.sspl;
    mainProgram = "graylog-forwarder";
    platforms = lib.platforms.unix;
  };

})
