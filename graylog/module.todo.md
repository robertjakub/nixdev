

- "./journal1:/usr/share/graylog/data/journal"
# only required if you want to store archives in a local folder; make sure the "archives" folder has 1100:1100 permissions on the host; don't use in Cloud Environments but work with s3 Backend instead
- "./archives:/usr/share/graylog/data/archives"

# only required if you want to use predefined content packs
- "./contentpacks:/etc/graylog/server/contentpacks:ro"

# only required if you want to use the data warehouse in a local folder; make sure the "warehouse" folder has 1100:1100 permissions on the host; don't use in Cloud Environments but work with s3 Backend instead
- "./datalake:/usr/share/graylog/data/datalake"

# only required if you want to use encrypted Syslog (stores the required certificates)
- "./input_tls:/etc/graylog/server/input_tls:ro"

# only required if you want to work with Lookup Tables for Enrichment
- "./lookuptables:/etc/graylog/server/lookuptables:ro"

# only required if you want to work with Geolocation Data
- "./maxmind:/etc/graylog/server/mmdb:ro"

# only required if you want to run script notifications (bash, any other script language); make sure the "notifications" folder has 1100:1100 permissions on the host
- "./notifications:/etc/graylog/server/notifications"

# only required if you want to add your own self-signed root certificate
- "./rootcerts:/certificates"
