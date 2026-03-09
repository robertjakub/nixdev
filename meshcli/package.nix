{ lib, python3Packages }:
python3Packages.toPythonApplication (
  python3Packages.meshcore-cli.overridePythonAttrs (prev: {
    dependencies = prev.dependencies ++ lib.concatAttrValues prev.optional-dependencies;
  })
)
