{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule (finalAttrs: {
  pname = "checkmate-capture";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "bluewave-labs";
    repo = "capture";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JFHtXbK8jL4gnGbanF2wVp4C8xKRt1aMtkbBQDeysD4=";
  };

  proxyVendor = true;
  vendorHash = "sha256-JkhDoafqpqoD05lBf5lCXMD3dSc3uArTW1lUBRWSp30=";

  ldflags = [ "-X main.Version=${finalAttrs.version}" ];

  doCheck = false;

  meta = {
    description = "A monitoring agent that collects and exposes hardware information through a RESTful API";
    homepage = "https://github.com/bluewave-labs/capture";
    changelog = "https://github.com/bluewave-labs/capture/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "capture";
    maintainers = with lib.maintainers; [ robertjakub ];
  };
})
