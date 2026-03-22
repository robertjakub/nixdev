{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-filter-messagesize";
    pluginName = "graylog-plugin-filter-messagesize";
    version = "0.0.2";
    src = fetchurl {
      url = "https://github.com/graylog-labs/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "1vx62yikd6d3lbwsfiyf9j6kx8drvn4xhffwv27fw5jzhfqr61ji";
    };
    meta = {
      homepage = "https://github.com/graylog-labs/graylog-plugin-filter-messagesize";
      description = "Prints out all messages that have an estimated size crossing a configured threshold during processing";
    };
  };
}
