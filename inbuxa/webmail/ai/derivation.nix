{
  lib,
  buildNpmPackage,
  fetchgit,
}:

buildNpmPackage rec {
  pname = "inbuxa-webmail";
  version = "2026.10.05";

  src = fetchgit {
    url = "https://git.coffeylabs.org/inbuxa/inbuxa-webmail.git";
    rev = "2174ccb7b3ff0210dfa31206dfbda56697471253"; # Latest commit from main
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual SRI hash
  };

  npmDepsHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Replace with actual npm deps hash

  # INBUXA builds front-end assets and a server side components using Node
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/inbuxa-webmail
    cp -r . $out/lib/node_modules/inbuxa-webmail
    makeWrapper ${buildNpmPackage}/bin/node $out/bin/inbuxa-webmail \
      --add-flags "$out/lib/node_modules/inbuxa-webmail/server/index.js" # Adjust to app entry point
    runHook postInstall
  '';

  meta = with lib; {
    description = "The INBUXA webmail clients: mail, calendars, contacts, files and filters over JMAP";
    homepage = "https://git.coffeylabs.org/inbuxa/inbuxa-webmail";
    license = licenses.agpl3Plus;
    platforms = platforms.linux;
  };
}
