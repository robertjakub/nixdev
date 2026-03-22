{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-jabber";
    pluginName = "graylog-plugin-jabber";
    version = "2.4.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "0zy27q8y0bv7i5nypsfxad4yiw121sbwzd194jsz2w08jhk3skl5";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-jabber";
      description = "Jabber Alarmcallback Plugin for Graylog";
    };
  };
}
