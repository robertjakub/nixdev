{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  openjdk17_headless,
  nixosTests,
  buildEnv,
  udev,
  systemd,
  plugins ? [ ],
}:
let
  pluginsDir = buildEnv {
    name = "graylog-plugins";
    paths = plugins;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "graylog_${lib.versions.majorMinor finalAttrs.version}";
  version = "6.3.10";

  src = fetchurl {
    url = "https://packages.graylog2.org/releases/graylog/graylog-${finalAttrs.version}.tgz";
    hash = "sha256-uHGlHOL8+6qFn2sSlzzp2Vl3lmCc7bpQD4eHDg6zmK0=";
  };

  dontBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [
    "--set-default"
    "JAVA_HOME"
    "${openjdk17_headless}"
    "--set-default"
    "JAVA_CMD"
    "$JAVA_HOME/bin/java"
  ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux) [
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ systemd ]}"
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ udev ]}"
  ];

  passthru.tests = { inherit (nixosTests) graylog; };

  installPhase = ''
    mkdir -p $out
    cp -r {graylog.jar,bin,plugin} $out
    wrapProgram $out/bin/graylogctl $makeWrapperArgs
    for plugin in `ls ${pluginsDir}/plugin/`; do
      ln -sf ${pluginsDir}/plugin/$plugin $out/plugin/$plugin || true
    done
  '';

  meta = {
    description = "Self-Managed Log Management";
    homepage = "https://www.graylog.org/";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    maintainers = with lib.maintainers; [
      bbenno
      etwas
      robertjakub
    ];
    license = lib.licenses.sspl;
    mainProgram = "graylogctl";
    platforms = lib.platforms.unix;
  };
})
