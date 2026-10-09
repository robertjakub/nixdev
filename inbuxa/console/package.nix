{
  buildNpmPackage,
  fetchFromGitea,
  ...
}:

buildNpmPackage (finalAttrs: {
  pname = "inbuxa-admin";
  version = "2026.10.5"; # Update this to the version you need

  src = fetchFromGitea {
    domain = "git.coffeylabs.org";
    owner = "inbuxa";
    repo = "inbuxa-admin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-NzjZBWhNaTQ1A4UbtNzzmpAWZUdwqq0s49E+QvY84uc=";
  };

  npmDepsHash = "sha256-S1ZzR7q2LSzRV3z7vN71gDQ62sKpKFAL79lJVIzE2g0=";

  # Injects environment variables at build time if needed
  # VITE_API_BASE_URL = "https://yourdomain.com";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/inbuxa-admin
    cp -r dist/* $out/share/inbuxa-admin/
    runHook postInstall
  '';

  postInstall = ''
    substituteInPlace $out/share/inbuxa-admin/index.html \
      --replace-fail '<meta name="api-base-url" content="" />' '<meta name="api-base-url" content="{{env \"INBUXA_API_URL\"}}" />'
  '';

})
