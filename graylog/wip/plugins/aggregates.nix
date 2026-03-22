{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-aggregates";
    pluginName = "graylog-plugin-aggregates";
    version = "2.4.0";
    src = fetchurl {
      url = "https://github.com/cvtienhoven/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "1c48almnjr0b6nvzagnb9yddqbcjs7yhrd5yc5fx9q7w3vxi50zp";
    };
    meta = {
      homepage = "https://github.com/cvtienhoven/graylog-plugin-aggregates";
      description = "Plugin that enables users to execute term searches and get notified when the given criteria are met";
    };
  };
}
