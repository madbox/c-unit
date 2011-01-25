raise( RuntimeError, "#{CONF_UNIT_KINDS_CONFIG} not found" ) unless File.exist?(CONF_UNIT_KINDS_CONFIG)
CONF_UNIT_KINDS = YAML.load(File.read( CONF_UNIT_KINDS_CONFIG ))
