{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  # dependencies
  openmeteo-sdk,
  niquests,
}:

buildPythonPackage (finalAttrs: {
  pname = "openmeteo-request";
  version = "1.7.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "open-meteo";
    repo = "python-requests";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RxVNG5hyGL/g7+1EPUcony4EAH4/WTyQg69oQDXuXKg=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'version = "0.1.0"' 'version = "${finalAttrs.version}"'
  '';

  build-system = [ hatchling ];

  dependencies = [
    openmeteo-sdk
    niquests
  ];

  pythonImportsCheck = [ "openmeteo_requests" ];

  meta = {
    description = "Open-Meteo API Python Client";
    homepage = "https://github.com/open-meteo/python-requests";
    changelog = "https://github.com/open-meteo/python-requests/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ robertjakub ];
  };
})
