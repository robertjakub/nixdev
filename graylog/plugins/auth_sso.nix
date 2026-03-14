{ glPlugin, fetchurl, ... }:
{
  plugin = glPlugin rec {
    pname = "graylog-auth-sso";
    pluginName = "graylog-plugin-auth-sso";
    version = "3.3.0";
    src = fetchurl {
      url = "https://github.com/Graylog2/${pluginName}/releases/download/${version}/${pluginName}-${version}.jar";
      sha256 = "1g47hlld8vzicd47b5i9n2816rbrhv18vjq8gp765c7mdg4a2jn8";
    };
    meta = {
      homepage = "https://github.com/Graylog2/graylog-plugin-auth-sso";
      description = "SSO support for Graylog through trusted HTTP headers set by load balancers or authentication proxies";
    };
  };
}
