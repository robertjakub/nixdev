{
  lib,
  stdenv,
  fetchFromGitHub,
  pnpm_11,
  nodejs_24,
  pnpmConfigHook,
  fetchPnpmDeps,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "traefik-proxy-admin";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "Janhouse";
    repo = "traefik-proxy-admin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-JoJC9ZU4KVhWW03En05H3wR2qQqn/0fCneanYriy7fQ=";
  };

  nativeBuildInputs = [
    pnpmConfigHook
    pnpm_11
    nodejs_24
  ];

  pnpmInstallFlags = [ "--no-strict-peer-dependencies" ];

  prePnpmInstall = ''
    cp -f ${./package.json} package.json
    cp -f ${./pnpm-lock.yaml} pnpm-lock.yaml
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit (finalAttrs) prePnpmInstall;
    inherit (finalAttrs) pnpmInstallFlags;
    pnpm = pnpm_11;
    fetcherVersion = 3;
    hash = "sha256-890jTBFY8sLKV5Blkd7S5Bjm9jU7gIG3j/FO8pPuUAg=";
  };

  patches = [ ./layout.patch ];

  postPatch = ''
    cp -f ${./next.config.ts} next.config.ts
    cp -f ${./eslint.config.mjs} eslint.config.mjs
    cp -f ${./geist.woff2} app/geist.woff2
    cp -f ${./geistmono.woff2} app/geistmono.woff2
  '';

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    mkdir $out
    mkdir $out/drizzle
    cp -R .next/standalone/server.js $out
    cp -R node_modules $out
    cp -R .next/standalone/.next $out
    cp -R .next/static $out/.next
    cp -R .next/BUILD_ID $out/.next/BUILD_ID
    cp -R ./drizzle/migrations/*.sql $out/drizzle
  '';

  meta = {
    description = "Traefik Dynamic Proxy Admin Panel";
    homepage = "https://github.com/Janhouse/traefik-proxy-admin";
    # license = lib.licenses.agpl3;
    platforms = lib.platforms.linux;
  };

})
