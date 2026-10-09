{
  buildNpmPackage,
  fetchFromGitea,
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

  npmDepsHash = "sha256-z0eWrw887OPwC1c+LrNYo0ZZZYFx6oOAoSzXmNPnVNc=";

  # buildPhase = ''
  #   runHook preBuild
  #   npm run build
  #   runHook postBuild
  # '';

  # installPhase = ''
  #   runHook preInstall
  #   mkdir -p $out/lib/node_modules/inbuxa-webmail
  #   cp -r . $out/lib/node_modules/inbuxa-webmail
  #   makeWrapper ${buildNpmPackage}/bin/node $out/bin/inbuxa-webmail \
  #     --add-flags "$out/lib/node_modules/inbuxa-webmail/server/index.js" # Adjust to app entry point
  #   runHook postInstall
  # '';

})
