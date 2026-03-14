{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-twiliosms";
    pluginName = "graylog-plugin-twiliosms";
    version = "1.0.0";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "0kwfv1zfj0fmxh9i6413bcsaxrn1vdwrzb6dphvg3dx27wxn1j1a";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-twiliosms";
      description = "Alarm callback plugin for integrating the Twilio SMS API into Graylog";
    };
  };
}
