{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-dnsresolver";
    pluginName = "graylog-plugin-dnsresolver";
    version = "1.2.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "0djlyd4w4mrrqfbrs20j1xw0fygqsb81snz437v9bf80avmcyzg1";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-dnsresolver";
      description = "Message filter plugin can be used to do DNS lookups for the source field in Graylog messages";
    };
  };
}
