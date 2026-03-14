{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-snmp";
    pluginName = "graylog-plugin-snmp";
    version = "0.3.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "1hkaklwzcsvqq45b98chwqxqdgnnbj4dg68agsll13yq4zx37qpp";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-snmp";
      description = "Graylog plugin to receive SNMP traps";
    };
  };
}
