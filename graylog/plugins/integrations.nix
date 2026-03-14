{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-integrations";
    pluginName = "graylog-plugin-integrations";
    version = "3.3.9";
    src = fetchurl {
      url = "https://downloads.graylog.org/releases/graylog-integrations/graylog-integrations-plugins-${version}.tgz";
      sha256 = "0q858ffmkinngyqqsaszcrx93zc4fg43ny0xb7vm0p4wd48hjyqc";
    };
    installPhase = ''
      mkdir -p $out/bin
      tar --strip-components=2 -xf $src
      cp ${pluginName}-${version}.jar $out/bin/${pluginName}-${version}.jar
    '';
    meta = {
      homepage = "https://github.com/Graylog2/graylog-plugin-integrations";
      description = "Collection of open source Graylog integrations that will be released together";
    };
  };
}
