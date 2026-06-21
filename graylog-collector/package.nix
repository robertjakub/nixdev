{
  buildGoModule,
  fetchFromGitHub,
  go-task,
  opentelemetry-collector-builder,
  ...
}:
buildGoModule (finalAttrs: {
  pname = "graylog-collector";
  proxyVendor = true;

  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "Graylog2";
    repo = "collector";
    tag = finalAttrs.version;
    hash = "sha256-a0sisP+IU9tjmP7o733/UcCeqLfGJqUk+aGpbc7ift8=";
  };

  # vendorHash = "";
  vendorHash = "sha256-uRNFzt8sk8z+WJtyzu0R05C+bUwb7PZJfjW8/U4QM/M=";

  nativeBuildInputs = [
    go-task
    opentelemetry-collector-builder
  ];

  ldflags = [
    "-s"
    "-X github.com/Graylog2/collector/superv/version.version=${finalAttrs.version}-nixos"
    "-X github.com/Graylog2/collector/superv/version.commit=f87169a"
  ];

  postPatch = ''
    substituteInPlace Taskfile.yml \
    	--replace-warn "sh: git rev-parse --short HEAD" "\'f87169a\'"
     substituteInPlace builder/builder-config.yaml \
     	--replace-warn "0.1.0-SNAPSHOT" "${finalAttrs.version}-nixos"
  '';

  buildPhase = ''
    runHook preBuild
    task build
    runHook postBuild
  '';

  overrideModAttrs = (
    _: {
      preBuild = ''
        (cd builder; go mod download)
        go get github.com/golang/protobuf@v1.5.4
        go get github.com/madflojo/testcerts@v1.5.0
        go get github.com/kylelemons/godebug@v1.1.0
        go get github.com/BurntSushi/toml@v0.3.1
        go get github.com/fsnotify/fsnotify@v1.9.0
        go get github.com/fortytw2/leaktest@v1.3.0
        go get github.com/google/go-tpm-tools@v0.4.7
        go get github.com/google/go-cmp@v0.7.0
        go get go.uber.org/goleak@v1.3.0
        go get gopkg.in/natefinch/lumberjack.v2@v2.0.0
        go get gopkg.in/check.v1@v1.0.0-20201130134442-10cb98267c6c
        go get github.com/open-telemetry/opentelemetry-collector-contrib/extension/storage@v0.153.0
        go get github.com/open-telemetry/opentelemetry-collector-contrib/pkg/pdatatest@v0.153.0
        go get github.com/open-telemetry/opentelemetry-collector-contrib/pkg/pdatautil@v0.153.0
        go get go.opentelemetry.io/otel/metric/x@v0.66.0
        go get go.opentelemetry.io/otel/sdk/log/logtest@v0.19.0
        go get go.opentelemetry.io/otel/sdk/log/logtest@v0.20.0
        go get go.opentelemetry.io/otel/log/logtest@v0.20.0
        go get go.opentelemetry.io/proto/slim/otlp@v1.10.0
        go get go.opentelemetry.io/proto/slim/otlp/collector/profiles/v1development@v0.3.0
        go get go.opentelemetry.io/collector/extension/extensionmiddleware/extensionmiddlewaretest@v0.153.0
        go get go.opentelemetry.io/collector/extension/zpagesextension@v0.153.0
        go get go.opentelemetry.io/collector/extension/extensionauth/extensionauthtest@v0.153.0
        go get go.opentelemetry.io/collector/service/telemetry/telemetrytest@v0.153.0
        go get go.opentelemetry.io/collector/internal/testutil@v0.153.0
      '';
    }
  );

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m 0755 target/graylog-collector $out/bin/graylog-collector
    runHook postInstall
  '';
})
