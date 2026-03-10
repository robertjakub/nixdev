{
  lib,
  pkgs,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  openjdk11_headless,
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
  pname = "graylog-enterprise_${lib.versions.majorMinor version}";
  inherit version;

  src = fetchurl {
    url = "https://packages.graylog2.org/releases/graylog-enterprise/graylog-enterprise-${version}.tgz";
    inherit hash;
  };

  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  makeWrapperArgs = [
    "--set-default"
    "JAVA_HOME"
    "${
      if (lib.versionAtLeast version "7.0") then
        openjdk21_headless
      else if (lib.versionAtLeast version "5.0") then
        openjdk17_headless
      else
        openjdk11_headless
    }"
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ systemd ]}"
  ];

  passthru.tests = { inherit (nixosTests) graylog; };

  buildInputs = with pkgs; [
    nss
    libxcb
    expat
    glib
  ];

  installPhase = ''
    mkdir -p $out
    cp -r {graylog.jar,plugin} $out
  ''
  + ''
    mkdir -p $out/bin
    install -m 0555 bin/graylogctl $out/bin
    install -m 0555 bin/chromedriver_start.sh $out/bin
  ''
  + lib.optionalString stdenv.hostPlatform.isx86_64 ''
    install -m 0555 bin/chromedriver_amd64 $out/bin
    install -m 0555 bin/headless_shell_amd64 $out/bin
  ''
  + lib.optionalString stdenv.hostPlatform.isAarch64 ''
    install -m 0555 bin/chromedriver_arm64 $out/bin
    install -m 0555 bin/headless_shell_arm64 $out/bin
  ''
  + lib.optionalString (lib.versionOlder version "4.3") ''
    cp -r lib $out
  ''
  + ''
    wrapProgram $out/bin/graylogctl $makeWrapperArgs
  '';

  meta = with lib; {
    description = "Graylog Enterprise log management solution";
    homepage = "https://www.graylog.org/";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    inherit license;
    inherit maintainers;
    mainProgram = "graylogctl";
    platforms = platforms.linux;
  };
}
