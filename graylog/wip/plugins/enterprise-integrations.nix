{
  glPlugin,
  fetchurl,
  lib,
  ...
}:
{
  plugin = glPlugin rec {
    pname = "graylog-enterprise-integrations";
    pluginName = "graylog-plugin-enterprise-integrations";
    version = "3.3.9";
    src = fetchurl {
      url = "https://downloads.graylog.org/releases/graylog-enterprise-integrations/graylog-enterprise-integrations-plugins-${version}.tgz";
      sha256 = "0yr2lmf50w8qw5amimmym6y4jxga4d7s7cbiqs5sqzvipgsknbwj";
    };
    installPhase = ''
      mkdir -p $out/bin
      tar --strip-components=2 -xf $src
      cp ${pluginName}-${version}.jar $out/bin/${pluginName}-${version}.jar
    '';
    meta = {
      homepage = "https://docs.graylog.org/en/3.3/pages/integrations.html#enterprise";
      description = "Integrations are tools that help Graylog work with external systems (unfree enterprise integrations)";
      license = lib.licenses.unfree;
    };
  };
}
