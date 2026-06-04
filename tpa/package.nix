{
  lib,
  stdenv,
  fetchFromGitHub,
  pnpm_10,
  nodejs_24,
  pnpmConfigHook,
  fetchPnpmDeps,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  ...
}:
let
  geistFont = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "geist-webfont";
    version = "1.7.2";
    srcs = [
      (fetchzip {
        url = "https://github.com/vercel/geist-font/releases/download/v${finalAttrs.version}/geist-font-v${finalAttrs.version}.zip";
        hash = "sha256-QP2PYwS/oTG0jDYdt9FGJAU8/n3yC+PJJW7WVUIyM/8=";
      })
    ];
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/
      find . -name "*.woff2" -exec cp {} $out \;
      runHook postInstall
    '';
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "traefik-proxy-admin";
  version = "1.16.0";

  NODE_ENV = "production";
  NEXT_TELEMETRY_DISABLED = 1;
  BUILD_ID = "nixos-${finalAttrs.version}";

  src = fetchFromGitHub {
    owner = "I-am-PUID-0";
    repo = "traefik-proxy-admin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-qmNJSLh3GPFP0yMViz7ocIgbP7M/yvaDNckwmz96WmU=";
  };

  nativeBuildInputs = [
    pnpmConfigHook
    pnpm_10
    nodejs_24
    makeWrapper
  ];

  patches = [ ./localfonts.patch ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-AYGN/j7b6W7XJp/2TGZN6hKfnlR5HZvd1IZYomg8wnI=";
  };

  postPatch = ''
    cp -f ${geistFont}/Geist\[wght\].woff2 src/app/geist.woff2
    cp -f ${geistFont}/GeistMono\[wght\].woff2 src/app/geistmono.woff2
  '';

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    mkdir $out
    rm -f .next/standalone/node_modules/.pnpm/node_modules/semver
    cp -R .next/standalone/server.js $out
    cp -R .next/standalone/node_modules $out
    cp -R .next/standalone/.next $out
    cp -R .next/static $out/.next
    cp -R .next/BUILD_ID $out/.next/BUILD_ID
    cp -R drizzle $out
    cp -R docs $out
    makeWrapper "${nodejs_24}/bin/node" $out/startserver
  '';

  meta = {
    description = "Traefik Dynamic Proxy Admin Panel";
    homepage = "https://github.com/Janhouse/traefik-proxy-admin";
    # license = lib.licenses.agpl3;
    platforms = lib.platforms.all;
    # mainProgram = "vite";
  };

})
