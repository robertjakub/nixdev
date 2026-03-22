{
  glPlugin,
  fetchurl,
  lib,
  ...
}:
{
  plugin = glPlugin rec {
    pname = "graylog-smseagle";
    pluginName = "graylog-plugin-smseagle";
    version = "1.0.1";
    src = fetchurl {
      url = "https://bitbucket.org/proximus/smseagle-graylog/raw/b99cfc349aafc7c94d4c2503f7c3c0bde67684d1/jar/${pluginName}-${version}.jar";
      sha256 = "sha256-rvvftzPskXRGs1Z9dvd/wFbQoIoNtEQIFxMIpSuuvf0=";
    };
    meta = {
      homepage = "https://bitbucket.org/proximus/smseagle-graylog/";
      description = "Alert/notification callback plugin for integrating the SMSEagle into Graylog";
      license = lib.licenses.gpl3Only;
    };
  };
}
