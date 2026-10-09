{
  buildNpmPackage,
  fetchFromGitea,
  makeWrapper,
  nodejs,
  ...
}:

buildNpmPackage (finalAttrs: {
  pname = "inbuxa-webmail";
  version = "2026.10.5-ge94508e"; # Update this to the version you need

  src = fetchFromGitea {
    domain = "git.coffeylabs.org";
    owner = "inbuxa";
    repo = "inbuxa-webmail";
    rev = "inbuxa-v${finalAttrs.version}";
    hash = "sha256-Jg+KDj2V3glLRGSQgZukeV6xMcsIW0Bmq/I9uWtv11Y=";
  };
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-80lGNKOLiqFmJ9up8x1r4Wlbgir2nZjlzzT6y19zGeo=";

  npmBuildScript = "build";
  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    cp -f ${./package-lock.json} package-lock.json
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/webmail
    cp -r node_modules $out/webmail
    mkdir -p $out/webmail/web
    mkdir -p $out/webmail/server
    cp -r web/dist $out/webmail/web
    cp -r server/dist $out/webmail/server
    cp -r scripts $out/webmail

    makeWrapper ${nodejs}/bin/node $out/bin/inbuxa-webmail \
      --add-flags "$out/webmail/server/dist/index.js" # Adjust to app entry point

    runHook postInstall
  '';

})
