{
  lib,
  stdenv,
  fetchFromGitLab,
  ...
}:
stdenv.mkDerivation rec {
  pname = "future-cyan-hyprcursor";
  version = "git-60fc69d6";

  src = fetchFromGitLab {
    owner = "Pummelfisch";
    repo = "future-cyan-hyprcursor";
    rev = "60fc69d603a6d7b99c1841a2c4cebd130b1aa357";
    hash = "sha256-TRDSQFCwofNj3PbGdE4Ro1hyQV7nJuE2Gc7YSUvv4k0=";
  };

  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r Future-Cyan-Hyprcursor_Theme $out/share/icons
    runHook postInstall
  '';

  meta = {
    description = "Future Cyan Hyprcursor";
    homepage = "https://gitlab.com/Pummelfisch/future-cyan-hyprcursor";
    license = lib.licenses.gpl3;
  };
}
