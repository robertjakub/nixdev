{
  buildGoModule,
  fetchFromGitHub,
  go-task,
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

  vendorHash = "sha256-v40+7VanJ8TBT9ySuS5ngWT5mW2fMQ5O/TNhhvNHluY=";

  nativeBuildInputs = [ go-task ];

  ldflags = [
    "-s"
    "-X github.com/Graylog2/collector/superv/version.version=${finalAttrs.version}-nixos"
    "-X github.com/Graylog2/collector/superv/version.commit=f87169a"
  ];

  postPatch = ''
    substituteInPlace Taskfile.yml --replace-warn "sh: git rev-parse --short HEAD" "f87169a"
    substituteInPlace builder/builder-config.yaml --replace-warn "0.1.0-SNAPSHOT" "${finalAttrs.version}-nixos"
    substituteInPlace builder/Taskfile.yml --replace-warn "go generate ." "true"
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
        mkdir -p dep
        cp ${./godep.mod} dep/go.mod
        (cd dep; go mod download)
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
