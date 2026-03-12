{ modulesPath, ... }:
{
  disabledModules = [ (modulesPath + "/services/logging/graylog.nix") ]; # FIXME

  imports = [
    ./checkmate/module.nix
    ./checkmate-capture/module.nix
    ./flame/module.nix
    ./graylog-sidecar/module.nix
    ./graylog/module.nix
  ];
}
