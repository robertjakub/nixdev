{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  unixtools,
}:
let
  pname = "checkmate-server";
  version = "3.8.1";

  src = fetchFromGitHub {
    owner = "bluewave-labs";
    repo = "Checkmate";
    tag = "v${version}";
    hash = "sha256-Ujl3vZZpKnvQ96ihr81LvWoZNlAQ8/jSvycXd6Q21ag=";
  };

  backend = buildNpmPackage (finalAttrs: {
    inherit version;
    pname = "${pname}-backend";
    src = "${src}/server";
    npmDepsHash = "sha256-HTIjPSbwnjDltHF6XuAlO7J+W6ED8y2EH1rAIaCPYS8=";
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist $out
      cp -r src/templates $out/dist
      cp -r node_modules $out/dist
      cp src/utils/demoMonitors.json $out/dist/utils
      cp openapi.json $out
      runHook postInstall
    '';
  });
in
buildNpmPackage (finalAttrs: {
  inherit version pname;
  src = "${src}/client";

  nativeBuildInputs = [ makeWrapper ];

  npmDepsHash = "sha256-Kl+PjolkBqRYjyVa9qxzrAuvrzT6EIAa8sprZM5uvEc=";

  postPatch = ''
    echo "VITE_APP_API_BASE_URL=/api/v1" > .env.production
    # vendored version do not resolve all required dependencies
    cp -f ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{public,backend}
    (cd dist; cp -r . $out/public)
    cp ${backend}/openapi.json $out
    (cd ${backend}/dist; cp -r . $out/backend)
    makeWrapper "${nodejs}/bin/node" $out/startserver \
      --set PATH ${lib.makeBinPath [ unixtools.ping ]};
    runHook postInstall
  '';

  meta = {
    description = "An open source uptime and infrastructure monitoring application";
    homepage = "https://checkmate.so";
    changelog = "https://github.com/bluewave-labs/Checkmate/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ robertjakub ];
  };
})
