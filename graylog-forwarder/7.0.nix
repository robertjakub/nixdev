{
  callPackage,
  lib,
  ...
}:
let
  buildGraylog = callPackage ./graylog-forwarder.nix { };
in
buildGraylog {
  version = "7.0";
  hash = "sha256-ICe7RoIZXIrB0O8KQLsbl3Cr5IkmhEf71I2YBMIVK00=";
  maintainers = with lib.maintainers; [ bbenno ];
  license = lib.licenses.sspl;
}
