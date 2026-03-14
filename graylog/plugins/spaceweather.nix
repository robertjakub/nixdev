{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-spaceweather";
    pluginName = "graylog-plugin-spaceweather";
    version = "1.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/spaceweather-input.jar";
      sha256 = "1mwqy3fhyy4zdwyrzvbr565xwf96xs9d3l70l0khmrm848xf8wz4";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-spaceweather";
      description = "Correlate proton density to the response time of your app and the ion temperature to your exception rate";
    };
  };
}
