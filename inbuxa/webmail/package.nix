{
  buildNpmPackage,
  fetchFromGitea,
  makeWrapper,
  nodejs,
  ...
}:

buildNpmPackage (finalAttrs: {
  pname = "inbuxa-webmail";
  version = "2026.10.9-g62936ab"; # Update this to the version you need

  src = fetchFromGitea {
    domain = "git.coffeylabs.org";
    owner = "inbuxa";
    repo = "inbuxa-webmail";
    rev = "inbuxa-v${finalAttrs.version}";
    hash = "sha256-2E3IhogK6r/zK5mQsL4uQa9/6F1opMiRFYDjt7Sbnnc=";
  };
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-YSKkM7+l+8RodOxnpG+vXupNnNn4kNueOGVV7TzpRvw=";

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
