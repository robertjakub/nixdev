{ stdenv, pkgs, ... }:
stdenv.mkDerivation (finalAttrs: {
  name = "java-cacerts";
  builder = pkgs.writeShellScript "java-cacerts-builder" ''
    ${pkgs.p11-kit.bin}/bin/trust \
      extract \
      --format=java-cacerts \
      --purpose=server-auth \
      $out
  '';
  outputs = [ "out" ];
})
