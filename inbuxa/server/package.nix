{
  rustPlatform,
  fetchFromGitea,
  libclang,
  clang,
  pkg-config,
  openssl,
  zlib,
  lib,
  zstd,
  bzip2,
  cacert,
  stdenv,
  writeTextFile,
  libredirect,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "inbuxa-server";
  version = "2026.10.8";

  src = fetchFromGitea {
    domain = "git.coffeylabs.org";
    owner = "inbuxa";
    repo = "inbuxa-server";
    rev = "v${finalAttrs.version}";
    hash = "sha256-w2nc4eiomr5f6drX8lIUae2AHm9FTPIYrtrpA/cb54I=";
  };

  # Nix blocks network access during compilation.
  # This hash tells Nix how to safely pre-cache all Cargo dependencies.
  # Leave this empty on your first build, then swap it with the hash Nix outputs.
  cargoHash = "sha256-OOjTySwTPAcXzKSVof5vi3AtdZmG7MHIgeoIM0lZHyU=";

  env = {
    # https://docs.rs/openssl/latest/openssl/#manual
    OPENSSL_NO_VENDOR = true;
    OPENSSL_DIR = lib.getDev openssl;
    OPENSSL_LIB_DIR = "${lib.getLib openssl}/lib";
    ZSTD_SYS_USE_PKG_CONFIG = true;
    LIBCLANG_PATH = "${libclang.lib}/lib";
  };
  # XXX: Check for ARM

  # Build configuration based on Inbuxa's upstream requirements
  buildFeatures = [
    "sqlite"
    "postgres"
    "mysql"
    "rocks"
    "s3"
    "redis"
  ];

  cargoBuildFlags = [
    "-p"
    "inbuxa"
  ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  doCheck = true;

  __darwinAllowLocalNetworking = true;

  sandboxProfile = lib.optionalString stdenv.hostPlatform.isDarwin ''
    (allow mach-lookup (global-name "com.apple.SystemConfiguration.configd"))
  '';

  preCheck =
    let
      nsswitch = writeTextFile {
        name = "nsswitch.conf";
        text = ''
          hosts: files dns
        '';
      };
      hosts = writeTextFile {
        name = "hosts";
        text = ''
          127.0.0.1 localhost
        '';
      };
      # ... panicked at tests/src/lib.rs:49:13: Errors: [ Build { ... , message: "Failed to read system DNS config: io error: No such file or directory (os error 2)" }, ... ]
      #   -> https://github.com/hickory-dns/hickory-dns/blob/v0.26.1/crates/resolver/src/system_conf/unix.rs#L25
      #   -> known issue: https://github.com/hickory-dns/hickory-dns/issues/2959
      resolvConf = writeTextFile {
        name = "resolv.conf";
        text = ''
          nameserver 127.0.0.1
        '';
      };
    in
    (lib.optionalString stdenv.hostPlatform.isLinux ''
      export NIX_REDIRECTS="/etc/nsswitch.conf=${nsswitch}:/etc/hosts=${hosts}:/etc/resolv.conf=${resolvConf}"
      export LD_PRELOAD="${libredirect}/lib/libredirect.so"
    '')
    + ''
      export STORE=RocksDb
    '';

  nativeBuildInputs = [
    clang
    pkg-config
    openssl
    cacert
  ];

  buildInputs = [
    openssl
    zlib
    zstd
    bzip2
  ];

  meta = {
    description = "A complete mail and collaboration server in one Rust binary";
    homepage = "https://inbuxa.org/";
    license = lib.licenses.agpl3Only;
  };
})
