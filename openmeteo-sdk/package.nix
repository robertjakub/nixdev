{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  # dependencies
  flatbuffers,
}:

buildPythonPackage (finalAttrs: {
  pname = "openmeteo-sdk";
  version = "1.25.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "open-meteo";
    repo = "sdk";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gt4oABUTytUOD/jCJdBQNGHqskLg8l7qXsvIG9Rc4X8=";
  };

  sourceRoot = "${finalAttrs.src.name}/python";

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'version = "0.0.0"' 'version = "${finalAttrs.version}"' \
      --replace-fail 'flatbuffers==25.9.23' 'flatbuffers>=25.9.23'
  '';

  build-system = [ hatchling ];

  dependencies = [ flatbuffers ];

  pythonImportsCheck = [ "openmeteo_sdk" ];

  meta = {
    description = "Python runtime library for Open-Meteo SDK Schema Files";
    homepage = "https://github.com/open-meteo/sdk";
    changelog = "https://github.com/open-meteo/sdk/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ robertjakub ];
  };
})
