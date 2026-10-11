{ python3Packages, ... }:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "sun2000-scrape";
  version = "0.0.1";

  format = "other";
  src = ./.;
  dontBuild = true;

  propagatedBuildInputs = with python3Packages; [
    pymodbus
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp scrape.py $out/bin/scrape
    chmod +x $out/bin/scrape

    runHook postInstall
  '';
})
