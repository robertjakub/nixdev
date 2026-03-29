{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  openjdk21_headless,
  nixosTests,
  buildEnv,
  udev,
  systemd,
  pkgs,
  plugins ? [ ],
}:
let
  pluginsDir = buildEnv {
    name = "graylog-plugins";
    paths = plugins;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "graylog_enterprise_${lib.versions.majorMinor finalAttrs.version}";
  version = "7.0.5";

  src = fetchurl {
    url = "https://packages.graylog2.org/releases/graylog-enterprise/graylog-enterprise-${finalAttrs.version}.tgz";
    hash = "sha256-2LjTmiIgoow2D6Ty7QnR3vFzkerxWnLmWDuEmc52FYo=";
  };

  dontBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [
    "--set-default"
    "JAVA_HOME"
    "${openjdk21_headless}"
    "--set-default"
    "JAVA_CMD"
    "$JAVA_HOME/bin/java"
  ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux) [
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ systemd ]}"
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ udev ]}"
  ];

  buildInputs = with pkgs; [
    nss
    libxcb
    expat
    glib
  ];

  passthru.tests = { inherit (nixosTests) graylog; };

  installPhase = ''
    mkdir -p $out
    cp -r {graylog.jar,plugin} $out

    mkdir -p $out/bin
    install -m 0555 bin/graylogctl $out/bin
    wrapProgram $out/bin/graylogctl $makeWrapperArgs
    install -m 0555 bin/chromedriver_start.sh $out/bin

    for plugin in `ls ${pluginsDir}/plugin/`; do
      ln -sf ${pluginsDir}/plugin/$plugin $out/plugin/$plugin || true
    done
  ''
  + lib.optionalString stdenv.hostPlatform.isx86_64 ''
    install -m 0555 bin/chromedriver_amd64 $out/bin
    install -m 0555 bin/headless_shell_amd64 $out/bin
  ''
  + lib.optionalString stdenv.hostPlatform.isAarch64 ''
    install -m 0555 bin/chromedriver_arm64 $out/bin
    install -m 0555 bin/headless_shell_arm64 $out/bin
  '';

  meta = {
    description = "Graylog Enterprise log management solution";
    homepage = "https://www.graylog.org/";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    maintainers = with lib.maintainers; [ robertjakub ];
    license = lib.licenses.sspl;
    mainProgram = "graylogctl";
    platforms = lib.platforms.linux;
  };
})
