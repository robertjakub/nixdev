{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-pagerduty";
    pluginName = "graylog-plugin-pagerduty";
    version = "2.0.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "0xhcwfwn7c77giwjilv7k7aijnj9azrjbjgd0r3p6wdrw970f27r";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-pagerduty";
      description = "Alarm callback plugin for integrating PagerDuty into Graylog";
    };
  };
}
