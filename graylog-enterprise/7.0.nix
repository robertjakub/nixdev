{ callPackage, lib, ... }:
let
  buildGraylog = callPackage ./graylog-enterprise.nix { };
in
buildGraylog {
  version = "7.0.1";
  hash = "sha256-10b7Bq6HBDDq+dfzUiKeq81EtYhq8tfASSFccQsotS4=";
  maintainers = with lib.maintainers; [ bbenno ];
  license = lib.licenses.sspl;
}
