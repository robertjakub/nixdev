{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:
buildGoModule (finalAttrs: {
  pname = "graylog-sidecar";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "Graylog2";
    repo = "collector-sidecar";
    tag = finalAttrs.version;
    hash = "sha256-xj/6Zx3BL95A2YvXjacN2tLz8+cD3QpPx566xRJ5Lus=";
  };

  vendorHash = "sha256-ud+OBUr0H08zMGPBIaQJwnalLRczvkDrmOTVRhoTSPk=";

  ldflags = [
    # gitrev/version req'd for a connectivity with Graylog-server
    "-X github.com/Graylog2/collector-sidecar/common.GitRevision=1069fb7"
    "-X github.com/Graylog2/collector-sidecar/common.CollectorVersion=${finalAttrs.version}"
    "-X github.com/Graylog2/collector-sidecar/common.CollectorVersionSuffix=-nixos"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m 0755 ../go/bin/collector-sidecar $out/bin/graylog-sidecar
    install -m 0755 ../go/bin/benchmarks $out/bin/graylog-sidecar-benchmarks
    runHook postInstall
  '';

  meta = {
    description = "Graylog Sidecar";
    homepage = "https://github.com/Graylog2/collector-sidecar";
    changelog = "https://github.com/Graylog2/collector-sidecar/releases/tag/v${finalAttrs.version}";
    mainProgram = "graylog-sidecar";
    license = lib.licenses.sspl;
    maintainers = with lib.maintainers; [ robertjakub ];
  };
})
