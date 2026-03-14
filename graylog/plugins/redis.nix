{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-redis";
    pluginName = "graylog-plugin-redis";
    version = "0.1.1";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "0dfgh6w293ssagas5y0ixwn0vf54i5iv61r5p2q0rbv2da6xvhbw";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-redis";
      description = "Redis plugin for Graylog";
    };
  };
}
