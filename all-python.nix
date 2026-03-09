{ pkgs, ... }:
let
  py = pkgs.python3.override {
    self = py;
    packageOverrides = _final: prev: {
      meshcore = meshcore;
      meshcore-cli = meshcore-cli;
      retry-requests = retry-requests;
      maidenhead = maidenhead;
      openmeteo-request = openmeteo-request;
      openmeteo-sdk = openmeteo-sdk;
      niquests = niquests;
      caldav = caldav;
    };
  };
  meshcore = py.pkgs.callPackage ./.merged/meshcore/package.nix { };
  meshcore-cli = py.pkgs.callPackage ./meshcore-cli/package.nix { };
  retry-requests = py.pkgs.callPackage ./retry-requests/package.nix { };
  maidenhead = py.pkgs.callPackage ./maidenhead/package.nix { };
  openmeteo-request = py.pkgs.callPackage ./openmeteo-request/package.nix { };
  openmeteo-sdk = py.pkgs.callPackage ./openmeteo-sdk/package.nix { };
  niquests = py.pkgs.callPackage ./niquests/package.nix { };
  caldav = py.pkgs.callPackage ./caldav/package.nix { };
in
{
  py = py;
}
