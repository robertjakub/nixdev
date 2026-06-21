{
  lib,
  stdenv,
  fetchFromGitHub,
  pnpm_10,
  nodejs_26,
  pnpmConfigHook,
  fetchPnpmDeps,
  makeWrapper,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "traefik-proxy-admin";
  version = "1.17.0";

  NODE_ENV = "production";
  NEXT_TELEMETRY_DISABLED = 1;
  BUILD_ID = "nixos-${finalAttrs.version}";

  src = fetchFromGitHub {
    owner = "I-am-PUID-0";
    repo = "traefik-proxy-admin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-BjGDh1CJLmAaTmxoWGEG3HeSMJiPPea+zoAR1vO+sho=";
  };

  nativeBuildInputs = [
    pnpmConfigHook
    pnpm_10
    nodejs_26
    makeWrapper
  ];

  __noChroot = stdenv.hostPlatform.isDarwin;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-hViYRfpQUAx1b6vB1wqks1awAOEo5l+QFcpqAs7uNbY=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    mkdir $out
    rm -f .next/standalone/node_modules/.pnpm/node_modules/semver
    cp -r .next/standalone/server.js $out
    cp -r .next/standalone/node_modules $out
    cp -r .next/standalone/.next $out
    cp -r .next/static $out/.next
    cp -r .next/BUILD_ID $out/.next/BUILD_ID
    cp -r drizzle $out
    cp -r docs $out
    cp -r public $out
    makeWrapper "${nodejs_26}/bin/node" $out/startserver
  '';

  meta = {
    description = "Traefik Dynamic Proxy Admin Panel";
    homepage = "https://github.com/I-am-PUID-0/traefik-proxy-admin";
    maintainers = with lib.maintainers; [ robertjakub ];
    license = with lib.licenses; [ gpl3 ];
    platforms = lib.platforms.all;
  };
})
