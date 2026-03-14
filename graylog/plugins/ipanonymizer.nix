{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-ipanonymizer";
    pluginName = "graylog-plugin-ipanonymizer";
    version = "1.1.2";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "0hd66751hp97ddkn29s1cmjmc2h1nrp431bq7d2wq16iyxxlygri";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-ipanonymizer";
      description = "Graylog-server plugin that replaces the last octet of IP addresses in messages with xxx";
    };
  };
}
