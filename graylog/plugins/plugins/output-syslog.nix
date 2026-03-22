{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "output-syslog";
    pluginName = "graylog-output-syslog";
    version = "6.3.5";
    src = fetchurl {
      url = "https://github.com/wizecore/graylog2-output-syslog/releases/download/v${version}/${pluginName}-${version}.jar";
      hash = "sha256-rjNN3vE0LCVkf4FoW5T7N6wL4eUsMjxOqMQXlRMRAeA=";
    };
    meta = {
      homepage = "https://github.com/wizecore/graylog2-output-syslog";
      description = "Plugin allows you to forward messages from a Graylog server in syslog format";
    };
  };
}
