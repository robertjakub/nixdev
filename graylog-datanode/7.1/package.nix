{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  openjdk21_headless,
  stdenvNoCC,
  coreutils,
  gnugrep,
}:
let
  version = "7.1.3";
  opensearch-version = "2.19.5";

  currentSystem = stdenv.hostPlatform.system;

  graylog-datanode-archs = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-aarch64";
  };
  gd-arch = graylog-datanode-archs.${currentSystem} or (throw "Unsupported system: ${currentSystem}");

  sources = {
    "x86_64-linux" = fetchurl {
      url = "https://downloads.graylog.org/releases/graylog-datanode/graylog-datanode-${version}-${gd-arch}.tgz";
      hash = "sha256-APJWHpvdBACh+IPfEw4lo1PiAhtx2fMWHXNlwrjfpWY=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://downloads.graylog.org/releases/graylog-datanode/graylog-datanode-${version}-${gd-arch}.tgz";
      hash = "";
    };
  };
  src = sources.${currentSystem} or (throw "Unsupported system: ${currentSystem}");

  opensearch-dist = "opensearch-${opensearch-version}-${gd-arch}";

  opensearch = stdenvNoCC.mkDerivation (finalAttrs: {
    version = opensearch-version;
    inherit src;
    pname = "graylog-datanode-opensearch_${opensearch-version}";
    sourceRoot = "graylog-datanode-${version}-${gd-arch}/dist/${opensearch-dist}";
    dontConfigue = true;

    nativeBuildInputs = [
      makeWrapper
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R bin config lib modules plugins $out

      substituteInPlace $out/bin/opensearch \
        --replace 'bin/opensearch-keystore' "$out/bin/opensearch-keystore"

      wrapProgram $out/bin/opensearch \
        --prefix PATH : "${
          lib.makeBinPath [
            gnugrep
            coreutils
          ]
        }" \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [ stdenv.cc.cc ]
        }:$out/plugins/opensearch-knn/lib/" \
        --set OPENSEARCH_JAVA_HOME "${openjdk21_headless}"

      wrapProgram $out/bin/opensearch-plugin --set OPENSEARCH_JAVA_HOME "${openjdk21_headless}"
      wrapProgram $out/bin/opensearch-cli --set OPENSEARCH_JAVA_HOME "${openjdk21_headless}"

      runHook postInstall
    '';

  });
in
stdenv.mkDerivation (finalAttrs: {
  inherit version src;
  pname = "graylog-datanode_${lib.versions.majorMinor finalAttrs.version}";

  dontBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [
    "--set-default JAVA_HOME ${openjdk21_headless}"
    "--set-default JAVA_CMD $JAVA_HOME/bin/java"
  ];

  installPhase = ''
    mkdir -p $out
    cp -r {graylog-datanode.jar,bin,lib,config} $out
    wrapProgram $out/bin/graylog-datanode $makeWrapperArgs
    mkdir -p $out/dist
    ln -sf ${opensearch} $out/dist/${opensearch-dist}
  '';

  meta = {
    description = "Graylog DataNode";
    homepage = "https://www.graylog.org/";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    maintainers = with lib.maintainers; [ robertjakub ];
    license = lib.licenses.sspl;
    mainProgram = "graylog-datanode";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
