{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "correlation-count";
    pluginName = "graylog-plugin-correlation-count";
    version = "7.0.0";
    src = fetchurl {
      url = "https://github.com/airbus-cyber/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      hash = "sha256-Kc+mQzDfprYe8ZBDeICC2+XDlSuasSFOYjBsIdXo8Vs=";
    };
    meta = {
      homepage = "https://github.com/airbus-cyber/graylog-plugin-correlation-count";
      description = "Correlation Count Plugin for Graylog";
    };
  };
}
