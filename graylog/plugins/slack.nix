{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-slack";
    pluginName = "graylog-plugin-slack";
    version = "3.1.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "067p8g94b007gypwyyi8vb6qhwdanpk8ah57abik54vv14jxg94k";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-slack";
      description = "Can notify Slack or Mattermost channels about triggered alerts in Graylog (Alarm Callback)";
    };
  };
}
