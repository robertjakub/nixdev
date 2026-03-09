{ lib, buildGoModule, fetchFromGitHub, pkgs, ... }:
buildGoModule rec {
  pname = "graylog-sidecar";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "Graylog2";
    repo = "collector-sidecar";
    tag = "${version}";
    hash = "sha256-jUt5nhtM5nJ2JUnIiOrbfSglXsWxsAIjGTbxzgb/7lc=";
  };

  vendorHash = "sha256-ud+OBUr0H08zMGPBIaQJwnalLRczvkDrmOTVRhoTSPk=";

  buildInputs = [ pkgs.go ];

  ldflags = [
    "-X github.com/Graylog2/collector-sidecar/common.GitRevision=6bb259f"
    "-X github.com/Graylog2/collector-sidecar/common.CollectorVersion=1.5.1"
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
    changelog = "https://github.com/Graylog2/collector-sidecar/releases/tag/v${version}";
    license = lib.licenses.sspl;
  };
}
