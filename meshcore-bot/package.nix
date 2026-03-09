{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  # dependencies
  aiohttp,
  aiohttp-retry,
  aiomqtt,
  bleak,
  colorlog,
  configparser,
  cryptography,
  ephem,
  feedparser,
  flask,
  flask-socketio,
  geopy,
  maidenhead,
  meshcore,
  meshcore-cli,
  openmeteo-request,
  openmeteo-sdk,
  paho-mqtt,
  pynacl,
  pyserial,
  python-dateutil,
  pytz,
  requests,
  requests-cache,
  retry-requests,
  schedule,
  urllib3,
}:

buildPythonPackage (finalAttrs: {
  pname = "meshcore-bot";
  version = "0.8.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "agessaman";
    repo = "meshcore-bot";
    tag = "v${finalAttrs.version}";
    hash = "sha256-462ckxUhA++9FfTMNR79o86qLqOHNrAcc8RPTqHUE3g=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'pyephem' 'ephem' \
      --replace-fail 'asyncio-mqtt' 'aiomqtt' \
      --replace-fail '"modules.commands", ' '"modules.commands", "modules.clients", '
  '';

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    aiohttp-retry
    aiomqtt
    bleak
    colorlog
    configparser
    cryptography
    ephem
    feedparser
    flask
    flask-socketio
    geopy
    maidenhead
    meshcore
    meshcore-cli
    openmeteo-request
    openmeteo-sdk
    paho-mqtt
    pynacl
    pyserial
    python-dateutil
    pytz
    requests
    requests-cache
    retry-requests
    schedule
    urllib3
  ];

  # Install translations to share directory for NixOS module compatibility
  postInstall = ''
    mkdir -p $out/share/meshcore-bot
    if [ -d "$src/translations" ]; then
      cp -r "$src/translations" $out/share/meshcore-bot/
    fi
  '';

  meta = {
    description = "A Python bot that connects to MeshCore mesh networks via serial port, BLE, or TCP/IP";
    homepage = "https://github.com/agessaman/meshcore-bot";
    changelog = "https://github.com/agessaman/meshcore-bot/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ robertjakub ];
  };
})
