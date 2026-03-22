- Graylog has been updated to 7.0
  This introduces some breaking changes Refer to the [upstream migration guide](https://go2docs.graylog.org/current/upgrading_graylog/upgrade_to_graylog_7.0.htm#BreakingChanges) for details.

- The `services.graylog` module has been refactored with the following breaking changes:
   - The `services.graylog.extraConfig` option has been removed. Configuration should now be specified directly via `services.graylog.settings`.
   - The `services.graylog.passwordSecret` option has been removed. Use `services.graylog.passwordSecretFile` to securely load from a file via systemd credencials.
   - The `services.graylog.rootPasswordSha2` option has been removed. Use `services.graylog.rootPasswordSha2File` to securely load from a file via systemd credencials.
