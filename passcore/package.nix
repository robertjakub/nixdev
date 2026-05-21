{
  lib,
  pkgs,
  buildNpmPackage,
  buildDotnetModule,
  nodejs,
  ...
}:
let
  pname = "passcore";
  version = "";

  src = pkgs.fetchgit {
    url = "https://github.com/unosquare/passcore.git";
    rev = "HEAD";
    sha256 = "sha256-ZdIndjdZdJWl/tMyWpx/xIekRs/xPSWUeSH+1Ws/KY0=";
  };

  client = buildNpmPackage {
    pname = "${pname}-client";
    inherit version;
    src = "${src}/src/Unosquare.PassCore.Web/ClientApp";
    npmDepsHash = "sha256-ZdPjOL8+u7pYdyVttNn62Uh3RMsR4qQ5ntKm0augPGk=";
    dontNpmBuild = true;

    nativeBuildInputs = [ nodejs ];

    postPatch = ''
      cp -f ${./package-lock.json} package-lock.json
      cp -f ${./package.json} package.json
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/ClientApp
      (cp -r . $out/ClientApp)
      runHook postInstall
    '';
  };
in
buildDotnetModule {
  inherit pname version src;

  nativeBuildInputs = [
    nodejs
    pkgs.dotnetCorePackages.sdk_6_0
  ];

  nugetDeps = ./deps.nix;
  projectFile = "Unosquare.PassCore.sln";
  buildType = "Release";

  postPatch = ''
    rm -rf src/Unosquare.PassCore.Web/ClientApp
    mkdir src/Unosquare.PassCore.Web/ClientApp
    cp -r ${client}/ClientApp/ src/Unosquare.PassCore.Web/
  '';

  buildPhase = ''
    ${pkgs.dotnetCorePackages.sdk_6_0}/bin/dotnet publish -o ./appbuild -c Release /p:PASSCORE_PROVIDER=LDAP Unosquare.PassCore.sln
  '';
  installPhase = ''
    runHook preInstall
    (cd appbuild; cp -r . $out)
    cp -f ${./appsettings.json} $out/appsettings.json.default
    rm -f $out/appsettings.json
    ln -s /etc/passcore/appsettings.json $out/appsettings.json
    runHook postInstall
  '';

  executables = [ ];
  dotnet-sdk = pkgs.dotnetCorePackages.sdk_6_0;
  dotnet-runtime = pkgs.dotnetCorePackages.aspnetcore_6_0;

  meta = with lib; {
    description = " A self-service password change utility for Active Directory.";
    homepage = "https://unosquare.github.io/passcore/";
    license = licenses.mit;
  };
}
