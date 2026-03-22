{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-internal-logs";
    pluginName = "graylog-plugin-internal-logs";
    version = "2.4.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "1jyy0wkjapv3xv5q957xxv2pcnd4n1yivkvkvg6cx7kv1ip75xwc";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-internal-logs";
      description = "Graylog plugin to record internal logs of Graylog efficiently instead of sending them over the network";
    };
  };
}
