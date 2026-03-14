{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-metrics";
    pluginName = "graylog-plugin-metrics";
    version = "1.3.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "1v1yzmqp43kxigh3fymdwki7pn21sk2ym3kk4nn4qv4zzkhz59vp";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-metrics";
      description = "Output plugin for integrating Graphite, Ganglia and StatsD with Graylog";
    };
  };
}
