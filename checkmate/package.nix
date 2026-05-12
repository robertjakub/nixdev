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
  version = "3.7.1";

  src = fetchFromGitHub {
    owner = "bluewave-labs";
    repo = "Checkmate";
    tag = "v${version}";
    hash = "sha256-Lq+XLNiOv47f/x5DFW9RejqsFO03A1KsEo8qMUG2hL4=";
  };

  backend = buildNpmPackage (finalAttrs: {
    inherit version;
    pname = "${pname}-backend";
    src = "${src}/server";
    npmDepsHash = "sha256-rZhD0e/OInzcmRjxie5tFKq1rpldqmNsSiDO9XxD498=";
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

  npmDepsHash = "sha256-ly3OS2ECuF+J9D9y2/wneWtEGLt3vYnTD6OzdbWzeso=";

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
