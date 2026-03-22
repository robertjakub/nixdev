{
  glPlugin,
  fetchurl,
  lib,
  ...
}:
{
  plugin = glPlugin rec {
    pname = "graylog-splunk";
    pluginName = "graylog-plugin-splunk";
    version = "0.5.0-rc.1";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "sha256-EwF/Dc8GmMJBTxH9xGZizUIMTGSPedT4bprorN6X9Os=";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-splunk";
      description = "Graylog output plugin that forwards one or more streams of data to Splunk via TCP";
      license = lib.licenses.gpl3Only;
    };
  };
}
