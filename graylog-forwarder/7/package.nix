{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  openjdk21_headless,
  udev,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "graylog-forwarder_${lib.versions.majorMinor finalAttrs.version}";
  version = "7.3";

  src = fetchurl {
    url = "https://downloads.graylog.org/releases/cloud/forwarder/${finalAttrs.version}/graylog-forwarder-${finalAttrs.version}-bin.tar.gz";
    hash = "sha256-c0JGlfWW5TR8UdisY/cue5VwnEt3RKAEiaqDqDO+DHc=	";
  };

  dontBuild = true;
  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [
    "--set-default JAVA_HOME ${openjdk21_headless}"
    "--set JAVA_CMD $JAVA_HOME/bin/java"
  ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux) [
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ udev ]}"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r forwarder.jar $out
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
