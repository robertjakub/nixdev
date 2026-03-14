{
  lib,
  stdenv,
  fetchurl,
  unzip,
  graylogPackage,
}:

let
  glPlugin =
    a@{
      pluginName,
      version,
      installPhase ? ''
        mkdir -p $out/bin
        cp $src $out/bin/${pluginName}-${version}.jar
      '',
      ...
    }:
    stdenv.mkDerivation (
      a
      // {
        inherit installPhase;
        dontUnpack = true;
        nativeBuildInputs = [ unzip ];
        meta = a.meta // {
          platforms = graylogPackage.meta.platforms;
          maintainers = (a.meta.maintainers or [ ]);
          sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
        };
      }
    );
in
{
  aggregates = (import plugins/aggregates.nix { glPlugin = glPlugin; }).plugin;
  auth_sso = (import plugins/auth_sso.nix { glPlugin = glPlugin; }).plugin;
  dnsresolver = (import plugins/dnsresolver.nix { glPlugin = glPlugin; }).plugin;
  enterprise-integrations =
    (import plugins/enterprise-integrations.nix { glPlugin = glPlugin; }).plugin;
  filter-messagesize = (import plugins/filter-messagesize.nix { glPlugin = glPlugin; }).plugin;
  integrations = (import plugins/integrations.nix { glPlugin = glPlugin; }).plugin;
  internal-logs = (import plugins/internal-logs.nix { glPlugin = glPlugin; }).plugin;
  ipanonymizer = (import plugins/ipanonymizer.nix { glPlugin = glPlugin; }).plugin;
  jabber = (import plugins/jabber.nix { glPlugin = glPlugin; }).plugin;
  metrics = (import plugins/metrics.nix { glPlugin = glPlugin; }).plugin;
  mongodb-profiler = (import plugins/mongodb-profiler.nix { glPlugin = glPlugin; }).plugin;
  pagerduty = (import plugins/pagerduty.nix { glPlugin = glPlugin; }).plugin;
  redis = (import plugins/redis.nix { glPlugin = glPlugin; }).plugin;
  slack = (import plugins/slack.nix { glPlugin = glPlugin; }).plugin;
  smseagle = (import plugins/smseagle.nix { glPlugin = glPlugin; }).plugin;
  snmp = (import plugins/snmp.nix { glPlugin = glPlugin; }).plugin;
  spaceweather = (import plugins/spaceweather.nix { glPlugin = glPlugin; }).plugin;
  splunk = (import plugins/splunk.nix { glPlugin = glPlugin; }).plugin;
  twiliosms = (import plugins/twiliosms.nix { glPlugin = glPlugin; }).plugin;
  twitter = (import plugins/twitter.nix { glPlugin = glPlugin; }).plugin;
}
