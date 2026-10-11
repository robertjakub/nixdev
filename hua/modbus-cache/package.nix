{ python3, ... }:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "sun2000-modbus_cache";
  version = "0.0.1";

  format = "other";
  src = ./.;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp modbus_cache_server.py $out/bin/modbus_cache
    chmod +x $out/bin/modbus_cache

    runHook postInstall
  '';
})
