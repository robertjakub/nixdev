{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "alert-wizard";
    pluginName = "graylog-plugin-alert-wizard";
    version = "7.0.0";
    src = fetchurl {
      url = "https://github.com/airbus-cyber/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      hash = "sha256-+kIIwf3KnCC2JBo7BAt3PvWgY4oH2Fn0WbVIroOFYa4=";
    };
    meta = {
      homepage = "https://github.com/airbus-cyber/graylog-plugin-alert-wizard";
      description = "Alert Wizard Plugin for Graylog";
    };
  };
}
