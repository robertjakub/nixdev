{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  python3,
  nodejs,
}:
let
  pname = "flame";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "pawelmalak";
    repo = "flame";
    rev = "v${version}";
    hash = "sha256-Slnft/tDtogjuTnQXus0Mp7y6AlOYjCV1riQ2M9cIc8=";
  };

  client = buildNpmPackage (finalAttrs: {
    pname = "${pname}-client";
    inherit version;
    src = "${src}/client";
    npmDepsHash = "sha256-IitL0qxu6/3y9x8XkW0dZLjsHTkNeQMHYsaq/LOwvrg=";
    npmInstallFlags = [ "--audit=false" ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/public
      (cd build; cp -r . $out/public)
      runHook postInstall
    '';
  });
in
buildNpmPackage (finalAttrs: {
  inherit pname version src;

  build-system = [
    nodejs
    python3
  ];
  npmDepsHash = "sha256-YGusqgF8xU6QBB0r0M8V0UZHLuSTdYlYyIMXnov7YEA=";

  patches = [
    ./disable-docker.patch
  ];

  npmBuildScript = "dev-init";

  postPatch = ''
    rm -r client
    cp -r ${client} client
  '';

  postInstall = ''
    rm -f $out/lib/node_modules/flame/.env
    rm -f $out/lib/node_modules/flame/client/public/flame.css
    ln -s client/public $out/lib/node_modules/flame/public
    ln -s /var/lib/flame $out/lib/node_modules/flame/data
    ln -s /var/lib/flame/flame.css $out/lib/node_modules/flame/public/flame.css
  '';

  meta = with lib; {
    description = "A self-hosted startpage for your server";
    changelog = "https://github.com/pawelmalak/flame/blob/master/CHANGELOG.md";
    homepage = "https://github.com/pawelmalak/flame";
    license = licenses.mit;
  };
})
